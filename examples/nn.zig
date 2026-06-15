const std = @import("std");
const math = std.math;

const NetType = f32;

// region [ Activation ]
const ActivationFunc = *const fn (x: NetType) NetType;
const ActivationDeriv = *const fn (x: NetType) NetType;

const Activation = struct {
    fn_ptr: ?ActivationFunc,
    deriv_ptr: ?ActivationDeriv,
};

fn reluAct(x: NetType) NetType {
    return if (x > 0.0) x else 0.0;
}

fn reluDeriv(x: NetType) NetType {
    return if (x > 0.0) 1.0 else 0.0;
}

fn sigmoidAct(x: NetType) NetType {
    return 1.0 / (1.0 + math.exp(-x));
}

fn sigmoidDeriv(sigmoid_out: NetType) NetType {
    return sigmoid_out * (1.0 - sigmoid_out);
}
// endregion

// region [ Neural network ]
fn randomNetType(rand: std.Random) NetType {
    if (NetType == f128)
        return @as(f128, rand.float(f64));
    return rand.float(NetType);
}

const NeuralNetwork = struct {
    num_layers: usize,
    layer_sizes: []usize,
    activations: []Activation,
    layers: [][]NetType,
    weights: [][]NetType,
    biases: [][]NetType,
    errors: [][]NetType,
    allocator: std.mem.Allocator,

    pub fn create(
        allocator: std.mem.Allocator,
        topology: []const usize,
        activations_list: []const Activation,
        rand: std.Random,
    ) !*NeuralNetwork {
        const self = try allocator.create(NeuralNetwork);
        errdefer allocator.destroy(self);

        self.allocator = allocator;
        self.num_layers = topology.len;

        self.layer_sizes = try allocator.alloc(usize, self.num_layers);
        @memcpy(self.layer_sizes, topology);

        self.activations = try allocator.alloc(Activation, self.num_layers);
        @memcpy(self.activations, activations_list);

        self.layers = try allocator.alloc([]NetType, self.num_layers);
        for (topology, 0..) |size, i| {
            self.layers[i] = try allocator.alloc(NetType, size);
            @memset(self.layers[i], 0.0);
        }

        const num_slices = self.num_layers - 1;
        self.weights = try allocator.alloc([]NetType, num_slices);
        self.biases = try allocator.alloc([]NetType, num_slices);
        self.errors = try allocator.alloc([]NetType, num_slices);

        for (0..num_slices) |layer_idx| {
            const rows = topology[layer_idx + 1];
            const cols = topology[layer_idx];

            self.weights[layer_idx] = try allocator.alloc(NetType, rows * cols);
            self.biases[layer_idx] = try allocator.alloc(NetType, rows);
            self.errors[layer_idx] = try allocator.alloc(NetType, rows);
            @memset(self.errors[layer_idx], 0.0);

            for (0..rows) |row| {
                const offset = row * cols;
                for (0..cols) |col|
                    self.weights[layer_idx][offset + col] = rand.float(NetType) * 2.0 - 1.0;
                self.biases[layer_idx][row] = rand.float(NetType) * 2.0 - 1.0;
            }
        }

        return self;
    }

    pub fn deinit(self: *NeuralNetwork) void {
        const allocator = self.allocator;

        for (self.layers) |layer|
            allocator.free(layer);
        allocator.free(self.layers);

        for (0..self.num_layers - 1) |layer_idx| {
            allocator.free(self.weights[layer_idx]);
            allocator.free(self.biases[layer_idx]);
            allocator.free(self.errors[layer_idx]);
        }

        allocator.free(self.weights);
        allocator.free(self.biases);
        allocator.free(self.errors);
        allocator.free(self.activations);
        allocator.free(self.layer_sizes);
        allocator.destroy(self);
    }

    pub fn forward(self: *NeuralNetwork, inputs: []const NetType) []NetType {
        @memcpy(self.layers[0], inputs);

        for (0..self.num_layers - 1) |layer_idx| {
            const out_size = self.layer_sizes[layer_idx + 1];
            const in_size = self.layer_sizes[layer_idx];
            const act_fn = self.activations[layer_idx + 1].fn_ptr.?;

            const layer_weights = self.weights[layer_idx];
            const curr_layer = self.layers[layer_idx];

            for (0..out_size) |out_idx| {
                var sum = self.biases[layer_idx][out_idx];
                const weight_offset = out_idx * in_size;

                for (0..in_size) |in_idx| {
                    sum += curr_layer[in_idx] * layer_weights[weight_offset + in_idx];
                }

                self.layers[layer_idx + 1][out_idx] = act_fn(sum);
            }
        }

        return self.layers[self.num_layers - 1];
    }

    pub fn backpropagate(self: *NeuralNetwork, targets: []const NetType, learning_rate: NetType) void {
        const out_layer_idx = self.num_layers - 1;
        const out_layer_size = self.layer_sizes[out_layer_idx];
        const out_deriv = self.activations[out_layer_idx].deriv_ptr.?;

        for (0..out_layer_size) |neuron_idx| {
            const out = self.layers[out_layer_idx][neuron_idx];
            const err = targets[neuron_idx] - out;
            self.errors[out_layer_idx - 1][neuron_idx] = err * out_deriv(out);
        }

        var layer_idx: isize = @intCast(out_layer_idx - 2);
        while (layer_idx >= 0) : (layer_idx -= 1) {
            const l_idx = @as(usize, @intCast(layer_idx));
            const current_size = self.layer_sizes[l_idx + 1];
            const next_size = self.layer_sizes[l_idx + 2];
            const hidden_deriv = self.activations[l_idx + 1].deriv_ptr.?;

            const next_errors = self.errors[l_idx + 1];
            const next_weights = self.weights[l_idx + 1];

            for (0..current_size) |neuron_idx| {
                var err: NetType = 0.0;
                for (0..next_size) |next_neuron_idx|
                    err += next_errors[next_neuron_idx] * next_weights[next_neuron_idx * current_size + neuron_idx];

                const out = self.layers[l_idx + 1][neuron_idx];
                self.errors[l_idx][neuron_idx] = err * hidden_deriv(out);
            }
        }

        for (0..self.num_layers - 1) |l_idx| {
            const out_size = self.layer_sizes[l_idx + 1];
            const in_size = self.layer_sizes[l_idx];

            const layer_weights = self.weights[l_idx];
            const layer_errors = self.errors[l_idx];
            const curr_layer = self.layers[l_idx];

            for (0..out_size) |out_idx| {
                const err_lr = learning_rate * layer_errors[out_idx];
                const weight_offset = out_idx * in_size;

                for (0..in_size) |in_idx|
                    layer_weights[weight_offset + in_idx] += err_lr * curr_layer[in_idx];

                self.biases[l_idx][out_idx] += err_lr;
            }
        }
    }

    pub fn lossMseDataset(self: *NeuralNetwork, dataset_inputs: []const []const NetType, dataset_targets: []const []const NetType) NetType {
        std.debug.assert(dataset_inputs.len == dataset_targets.len);
        std.debug.assert(dataset_inputs.len > 0);

        var total_loss: NetType = 0.0;
        const out_layer_idx = self.num_layers - 1;
        const output_size = self.layer_sizes[out_layer_idx];

        for (dataset_inputs, dataset_targets) |sample_input, sample_target| {
            const outputs = self.forward(sample_input);
            var sample_loss: NetType = 0.0;

            for (0..output_size) |out_idx| {
                const diff = sample_target[out_idx] - outputs[out_idx];
                sample_loss += diff * diff;
            }

            total_loss += sample_loss / @as(NetType, @floatFromInt(output_size));
        }

        return total_loss / @as(NetType, @floatFromInt(dataset_inputs.len));
    }
};
// endregion

const EPOCHS = 10_000_000;
const LEARNING_RATE = 0.001;

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var prng = std.Random.DefaultPrng.init(@intFromPtr(&allocator));
    const rand = prng.random();

    std.debug.print("Neural Zig\n", .{});

    // create neural network
    const topology = [_]usize{ 2, 9, 1 };
    const activations = [_]Activation{
        .{ .fn_ptr = null, .deriv_ptr = null },
        .{ .fn_ptr = reluAct, .deriv_ptr = reluDeriv },
        .{ .fn_ptr = sigmoidAct, .deriv_ptr = sigmoidDeriv },
    };

    const nn = try NeuralNetwork.create(allocator, &topology, &activations, rand);
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

    const progress_step = EPOCHS / 100;
    for (0..EPOCHS) |epoch| {
        if (epoch % progress_step == 0)
            std.debug.print("training progress: \x1b[32m{d:.0}%\x1b[0m\r", .{((@as(f32, @floatFromInt(epoch)) / EPOCHS) * 100.0)});

        for (inputs, 0..) |sample_input, sample_idx| {
            _ = nn.forward(sample_input);
            nn.backpropagate(targets[sample_idx], LEARNING_RATE);
        }
    }

    // print results
    std.debug.print("\nresults:\n", .{});
    for (inputs, targets) |input, target| {
        const outputs = nn.forward(input);

        std.debug.print("[{d:.1}, {d:.1}] -> [{d:.12}] (exp. [{d:.1}])\n", .{
            input[0], input[1], outputs[0], target[0],
        });
    }

    const final_loss = nn.lossMseDataset(&inputs, &targets);
    std.debug.print("\x1b[1mmse loss\x1b[0m: \x1b[31;1m{d:.12}\x1b[0m\n", .{final_loss});
}
