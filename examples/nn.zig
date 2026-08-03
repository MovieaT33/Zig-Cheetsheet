const std = @import("std");
const Allocator = std.mem.Allocator;
const math = std.math;

const NetType = f32; // f32 is the fastest
const ActivationFunc = *const fn (x: NetType) NetType;
const ActivationDeriv = *const fn (x: NetType) NetType;

const Activation = struct {
    fn_ptr: ?ActivationFunc,
    deriv_ptr: ?ActivationDeriv,
};

/// RELU
fn reluAct(x: NetType) NetType {
    return if (x > 0) x else 0;
}

fn reluDeriv(x: NetType) NetType {
    return if (x > 0) 1 else 0;
}

/// Sigmoid
fn sigmoidAct(x: NetType) NetType {
    return 1 / (1 + math.exp(-x));
}

fn sigmoidDeriv(sigmoid_out: NetType) NetType {
    return sigmoid_out * (1 - sigmoid_out);
}

const NeuralNetwork = struct {
    const Self = @This();

    allocator: Allocator,
    layer_count: usize,
    layer_sizes: []usize,
    neurons: [][]NetType,
    weights: [][]NetType,
    biases: [][]NetType,
    activations: []Activation,
    deltas: [][]NetType,

    inline fn randomNetValue(rand: std.Random) NetType {
        if (NetType == f16)
            return @as(f16, @floatCast(rand.float(f32)));
        if (NetType == f128)
            return @as(f128, rand.float(f64));
        return rand.float(NetType);
    }

    fn create(
        allocator: Allocator,
        topology: []const usize,
        activations: []const Activation,
        rand: std.Random,
    ) Allocator.Error!*Self {
        const self = try allocator.create(Self);
        errdefer allocator.destroy(self);

        self.allocator = allocator;
        self.layer_count = topology.len;

        self.layer_sizes = try allocator.alloc(usize, self.layer_count);
        @memcpy(self.layer_sizes, topology);

        self.neurons = try allocator.alloc([]NetType, self.layer_count);
        for (topology, 0..) |size, i| {
            self.neurons[i] = try allocator.alloc(NetType, size);
            @memset(self.neurons[i], 0);
        }

        const connection_count = self.layer_count - 1;
        self.weights = try allocator.alloc([]NetType, connection_count);
        self.biases = try allocator.alloc([]NetType, connection_count);

        self.activations = try allocator.alloc(Activation, self.layer_count);
        @memcpy(self.activations, activations);

        self.deltas = try allocator.alloc([]NetType, connection_count);

        for (0..connection_count) |layer| {
            const cols = topology[layer];
            const rows = topology[layer + 1];

            self.weights[layer] = try allocator.alloc(NetType, cols * rows);
            self.biases[layer] = try allocator.alloc(NetType, rows);
            self.deltas[layer] = try allocator.alloc(NetType, rows);
            @memset(self.deltas[layer], 0);

            for (0..rows) |row| {
                for (0..cols) |col|
                    self.weights[layer][cols * row + col] = randomNetValue(rand) * 2 - 1; // -1 -> 1

                self.biases[layer][row] = randomNetValue(rand) * 2 - 1; // -1 -> 1
            }
        }

        return self;
    }

    fn deinit(self: *Self) void {
        const allocator = self.allocator;

        for (self.neurons) |layer_neurons|
            allocator.free(layer_neurons);
        allocator.free(self.neurons);

        allocator.free(self.layer_sizes);

        for (0..self.layer_count - 1) |layer_idx| {
            allocator.free(self.weights[layer_idx]);
            allocator.free(self.biases[layer_idx]);
            allocator.free(self.deltas[layer_idx]);
        }
        allocator.free(self.weights);

        allocator.free(self.biases);
        allocator.free(self.activations);
        allocator.free(self.deltas);

        allocator.destroy(self);
    }

    fn forward(self: *Self, inputs: []const NetType) []NetType {
        @memcpy(self.neurons[0], inputs);

        for (0..self.layer_count - 1) |layer_idx| {
            const in_size = self.layer_sizes[layer_idx];
            const out_size = self.layer_sizes[layer_idx + 1];

            const layer_neurons = self.neurons[layer_idx];
            const layer_weights = self.weights[layer_idx];
            const activation_fn = self.activations[layer_idx + 1].fn_ptr.?;

            for (0..out_size) |out_idx| {
                const weight_offset = in_size * out_idx;
                var weighted_sum = self.biases[layer_idx][out_idx];

                for (0..in_size) |in_idx| {
                    const neuron_value = layer_neurons[in_idx];
                    const weight = layer_weights[weight_offset + in_idx];
                    weighted_sum += neuron_value * weight;
                }

                self.neurons[layer_idx + 1][out_idx] = activation_fn(weighted_sum);
            }
        }

        return self.neurons[self.layer_count - 1];
    }

    fn backpropagate(
        self: *Self,
        targets: []const NetType,
        learning_rate: NetType,
    ) void {
        const out_layer_idx = self.layer_count - 1;
        const out_layer_size = self.layer_sizes[out_layer_idx];
        const out_deriv_fn = self.activations[out_layer_idx].deriv_ptr.?;

        for (0..out_layer_size) |neuron_idx| {
            const out_value = self.neurons[out_layer_idx][neuron_idx];
            const @"error" = targets[neuron_idx] - out_value;
            self.deltas[out_layer_idx - 1][neuron_idx] = @"error" * out_deriv_fn(out_value);
        }

        var layer_idx_signed: isize = @intCast(out_layer_idx - 2);
        while (layer_idx_signed >= 0) : (layer_idx_signed -= 1) {
            const layer_idx: usize = @intCast(layer_idx_signed);

            const current_size = self.layer_sizes[layer_idx + 1];
            const next_size = self.layer_sizes[layer_idx + 2];

            const next_deltas = self.deltas[layer_idx + 1];
            const next_weights = self.weights[layer_idx + 1];

            const hidden_deriv_fn = self.activations[layer_idx + 1].deriv_ptr.?;

            for (0..current_size) |neuron_idx| {
                var @"error": NetType = 0;
                for (0..next_size) |next_neuron_idx| {
                    const next_delta = next_deltas[next_neuron_idx];
                    const weight = next_weights[current_size * next_neuron_idx + neuron_idx];
                    @"error" += next_delta * weight;
                }

                const out_value = self.neurons[layer_idx + 1][neuron_idx];
                self.deltas[layer_idx][neuron_idx] = @"error" * hidden_deriv_fn(out_value);
            }
        }

        for (0..self.layer_count - 1) |layer_idx| {
            const in_size = self.layer_sizes[layer_idx];
            const out_size = self.layer_sizes[layer_idx + 1];

            const layer_weights = self.weights[layer_idx];
            const layer_deltas = self.deltas[layer_idx];
            const layer_neurons = self.neurons[layer_idx];

            for (0..out_size) |out_idx| {
                const weight_offset = in_size * out_idx;
                const scaled_delta = layer_deltas[out_idx] * learning_rate;

                for (0..in_size) |in_idx|
                    layer_weights[weight_offset + in_idx] += scaled_delta * layer_neurons[in_idx];

                self.biases[layer_idx][out_idx] += scaled_delta;
            }
        }
    }

    fn lossMseDataset(
        self: *Self,
        dataset_inputs: []const []const NetType,
        dataset_targets: []const []const NetType,
    ) NetType {
        std.debug.assert(dataset_inputs.len == dataset_targets.len);
        std.debug.assert(dataset_inputs.len > 0);

        const out_layer_idx = self.layer_count - 1;
        const out_size = self.layer_sizes[out_layer_idx];

        var total_loss: NetType = 0;

        for (dataset_inputs, dataset_targets) |sample_input, sample_target| {
            const outputs = self.forward(sample_input);
            var sample_loss: NetType = 0;

            for (0..out_size) |out_idx| {
                const out_error = sample_target[out_idx] - outputs[out_idx];
                const squared_error = out_error * out_error;
                sample_loss += squared_error;
            }

            total_loss += sample_loss / @as(NetType, @floatFromInt(out_size));
        }

        return total_loss / @as(NetType, @floatFromInt(dataset_inputs.len));
    }
};

const epochs = 1_000_000;
const lr = 0.005;

pub fn main(init: std.process.Init) !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var prng: std.Random.DefaultPrng = .init(blk: {
        const now: std.Io.Timestamp = .now(init.io, .real);
        const seed = now.toNanoseconds();
        break :blk @intCast(seed);
    });
    const rand = prng.random();

    std.debug.print("Neural Zig\n", .{});

    // create NN
    const topology = [_]usize{ 2, 9, 1 };
    const activations = [_]Activation{
        .{ .fn_ptr = null, .deriv_ptr = null },
        .{ .fn_ptr = reluAct, .deriv_ptr = reluDeriv },
        .{ .fn_ptr = sigmoidAct, .deriv_ptr = sigmoidDeriv },
    };

    const nn = try NeuralNetwork.create(
        allocator,
        &topology,
        &activations,
        rand,
    );
    defer nn.deinit();

    // train
    const inputs = [_][]const NetType{
        &[_]NetType{ 0.0, 0.0 }, &[_]NetType{ 0.0, 0.5 }, &[_]NetType{ 0.0, 1.0 },
        &[_]NetType{ 0.5, 0.0 }, &[_]NetType{ 0.5, 0.5 }, &[_]NetType{ 0.5, 1.0 },
        &[_]NetType{ 1.0, 0.0 }, &[_]NetType{ 1.0, 0.5 }, &[_]NetType{ 1.0, 1.0 },
    };
    const targets = [_][]const NetType{
        &[_]NetType{0.1}, &[_]NetType{0.2}, &[_]NetType{0.3},
        &[_]NetType{0.4}, &[_]NetType{0.5}, &[_]NetType{0.6},
        &[_]NetType{0.7}, &[_]NetType{0.8}, &[_]NetType{0.9},
    };

    const progress_step = epochs / 1_000;
    for (0..epochs) |epoch| {
        if (epoch % progress_step == 0) {
            const loss = nn.lossMseDataset(&inputs, &targets);
            std.debug.print(
                "training progress: \x1b[32m{d:.0}%\x1b[0m | loss: {d:.12}\r",
                .{
                    @as(f32, @floatFromInt(epoch)) / @as(f32, @floatFromInt(epochs)) * 100,
                    loss,
                },
            );
        }

        for (inputs, 0..) |sample_input, sample_idx| {
            _ = nn.forward(sample_input);
            nn.backpropagate(targets[sample_idx], lr);
        }
    }

    // print results
    std.debug.print("\nresults:\n", .{});
    for (inputs, targets) |input, target| {
        const outputs = nn.forward(input);

        std.debug.print(
            "[{d:.1}, {d:.1}] > [{d:.12}] < [\x1b[38;2;241;250;140m{d:.1}\x1b[0m]\n",
            .{ input[0], input[1], outputs[0], target[0] },
        );
    }

    const final_loss = nn.lossMseDataset(&inputs, &targets);
    std.debug.print(
        "\x1b[1mmse loss\x1b[0m: \x1b[31;1m{d:.12}\x1b[0m\n",
        .{final_loss},
    );
}
