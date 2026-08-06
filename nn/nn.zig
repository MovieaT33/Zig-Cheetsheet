const std = @import("std");
const math = std.math;
const Allocator = std.mem.Allocator;

const Activation = @import("activation.zig").Activation;
const NetType = @import("config.zig").NetType;

pub const NeuralNetwork = struct {
    const Self = @This();

    const Buffers = struct {
        neurons: []NetType,
        weights: []NetType,
        biases: []NetType,
        deltas: []NetType,
    };

    const Offsets = struct {
        layers: []usize,
        weights: []usize,
        biases: []usize,
    };

    const Layout = struct {
        neurons: usize,
        weights: usize,
        biases: usize,
    };

    layer_sizes: []usize,

    buffers: Buffers,
    offsets: Offsets,

    activations: []Activation,

    allocator: Allocator,

    fn randomNetValue(rand: std.Random) NetType {
        return switch (NetType) {
            f16 => @as(f16, @floatCast(rand.float(f32))),
            f128 => @as(f128, rand.float(f64)),
            else => rand.float(NetType),
        };
    }

    fn randomBufferValue(rand: std.Random) NetType {
        return randomNetValue(rand) * 2 - 1; // [-1; 1)
    }

    fn randomizeBuffers(self: *Self, rand: std.Random) void {
        const connection_count = self.layer_sizes.len - 1;

        for (0..connection_count) |layer| {
            const in_size = self.layer_sizes[layer];
            const out_size = self.layer_sizes[layer + 1];
            const weight_count = in_size * out_size;

            const weight_base = self.offsets.weights[layer];
            const bias_base = self.offsets.biases[layer];

            const weight_layer =
                self.buffers.weights[weight_base..][0..weight_count];
            const bias_layer =
                self.buffers.biases[bias_base..][0..out_size];

            // Randomize weights and biases.
            for (weight_layer) |*weight|
                weight.* = randomBufferValue(rand);

            for (bias_layer) |*bias|
                bias.* = randomBufferValue(rand);
        }
    }

    fn mutateSlice(
        slice: []NetType,
        mutation_rate: NetType,
        mutation_strength: NetType,
        rand: std.Random,
    ) void {
        for (slice) |*value| {
            const should_mutate =
                randomNetValue(rand) < mutation_rate;

            if (should_mutate) {
                const mutation =
                    randomBufferValue(rand) * mutation_strength;

                value.* += mutation;
            }
        }
    }

    pub fn mutateBuffers(
        self: *Self,
        mutation_rate: NetType,
        mutation_strength: NetType,
        rand: std.Random,
    ) void {
        const buffers = self.buffers;

        mutateSlice(
            buffers.weights,
            mutation_rate,
            mutation_strength,
            rand,
        );

        mutateSlice(
            buffers.biases,
            mutation_rate,
            mutation_strength,
            rand,
        );
    }

    fn allocOffsets(self: *Self) Allocator.Error!void {
        const layer_count = self.layer_sizes.len;
        const connection_count = layer_count - 1;

        self.offsets.layers =
            try self.allocator.alloc(usize, layer_count);

        self.offsets.weights =
            try self.allocator.alloc(usize, connection_count);

        self.offsets.biases =
            try self.allocator.alloc(usize, connection_count);
    }

    fn calculateLayout(self: *Self) Layout {
        const connection_count = self.layer_sizes.len - 1;

        var neuron_count: usize = 0;
        var weight_count: usize = 0;
        var bias_count: usize = 0;

        // Calculate neuron offsets for each layer.
        for (self.layer_sizes, 0..) |layer_size, layer| {
            self.offsets.layers[layer] = neuron_count;
            neuron_count += layer_size;
        }

        // Calculate weight and bias offsets for each connection.
        for (0..connection_count) |connection| {
            const in_size = self.layer_sizes[connection];
            const out_size = self.layer_sizes[connection + 1];

            self.offsets.weights[connection] = weight_count;
            self.offsets.biases[connection] = bias_count;

            weight_count += in_size * out_size;
            bias_count += out_size;
        }

        return .{
            .neurons = neuron_count,
            .weights = weight_count,
            .biases = bias_count,
        };
    }

    fn allocParameters(
        self: *Self,
        layout: Layout,
    ) Allocator.Error!void {
        self.buffers.neurons =
            try self.allocator.alloc(NetType, layout.neurons);

        self.buffers.weights =
            try self.allocator.alloc(NetType, layout.weights);

        self.buffers.biases =
            try self.allocator.alloc(NetType, layout.biases);

        self.buffers.deltas =
            try self.allocator.alloc(NetType, layout.biases);

        self.activations =
            try self.allocator.alloc(
                Activation,
                self.layer_sizes.len,
            );
    }

    fn initState(self: *Self, activations: []const Activation) void {
        @memset(self.buffers.neurons, 0);
        @memset(self.buffers.deltas, 0);

        @memcpy(
            self.activations,
            activations,
        );
    }

    pub fn init(
        topology: []const usize,
        activations: []const Activation,
        allocator: Allocator,
        rand: std.Random,
    ) Allocator.Error!*Self {
        const self = try allocator.create(Self);
        errdefer self.deinit();

        self.allocator = allocator;

        self.layer_sizes =
            try allocator.dupe(usize, topology);

        try self.allocOffsets();

        const layout = self.calculateLayout();

        try self.allocParameters(layout);

        self.initState(activations);

        self.randomizeBuffers(rand);

        return self;
    }

    pub fn deinit(self: *Self) void {
        const allocator = self.allocator;
        defer allocator.destroy(self);

        const buffers = self.buffers;
        const offsets = self.offsets;

        allocator.free(self.layer_sizes);

        allocator.free(buffers.neurons);
        allocator.free(buffers.weights);
        allocator.free(buffers.biases);
        allocator.free(buffers.deltas);

        allocator.free(offsets.layers);
        allocator.free(offsets.weights);
        allocator.free(offsets.biases);

        allocator.free(self.activations);
    }

    pub fn clone(
        self: *const Self,
        rand: std.Random,
    ) Allocator.Error!*Self {
        return try .create(
            self.layer_sizes,
            self.activations,
            self.allocator,
            rand,
        );
    }

    pub fn copyParameters(self: *Self, source: *const Self) void {
        std.debug.assert(self.buffers.weights.len == source.buffers.weights.len);
        std.debug.assert(self.buffers.biases.len == source.buffers.biases.len);
        std.debug.assert(self.activations.len == source.activations.len);

        @memcpy(
            self.buffers.weights,
            source.buffers.weights,
        );

        @memcpy(
            self.buffers.biases,
            source.buffers.biases,
        );

        @memcpy(
            self.activations,
            source.activations,
        );
    }

    pub fn calculateMse(
        self: *Self,
        inputs: []const NetType,
        targets: []const NetType,
    ) NetType {
        const input_size = self.layer_sizes[0];
        std.debug.assert(inputs.len % input_size == 0);

        const sample_count = inputs.len / input_size;
        std.debug.assert(sample_count > 0);

        const output_layer = self.layer_sizes.len - 1;
        const output_size = self.layer_sizes[output_layer];
        std.debug.assert(targets.len == output_size * sample_count);

        const output_base = self.offsets.layers[output_layer];
        const output =
            self.buffers.neurons[output_base..][0..output_size];

        const inverse_output_size =
            1 / @as(NetType, @floatFromInt(output_size));
        const inverse_sample_count =
            1 / @as(NetType, @floatFromInt(sample_count));

        var total_loss: NetType = 0;

        for (0..sample_count) |sample| {
            const input_base = sample * input_size;
            const target_base = sample * output_size;

            const input =
                inputs[input_base..][0..input_size];
            const target =
                targets[target_base..][0..output_size];

            self.forward(input);

            var sample_loss: NetType = 0;

            for (output, target) |prediction, expected| {
                const @"error" = expected - prediction;
                sample_loss += @"error" * @"error";
            }

            total_loss += sample_loss * inverse_output_size;
        }

        return total_loss * inverse_sample_count;
    }

    pub fn forward(self: *Self, inputs: []const NetType) void {
        std.debug.assert(inputs.len == self.layer_sizes[0]);

        // Copy the input values into the first layer of neurons.
        @memcpy(
            self.buffers.neurons[0..inputs.len],
            inputs,
        );

        const connection_count = self.layer_sizes.len - 1;

        for (0..connection_count) |layer| {
            const next_layer = layer + 1;

            const in_size = self.layer_sizes[layer];
            const out_size = self.layer_sizes[next_layer];
            const weight_count = in_size * out_size;

            const layer_base = self.offsets.layers[layer];
            const next_layer_base = self.offsets.layers[next_layer];
            const weight_base = self.offsets.weights[layer];
            const bias_base = self.offsets.biases[layer];

            const input_layer =
                self.buffers.neurons[layer_base..][0..in_size];
            const output_layer =
                self.buffers.neurons[next_layer_base..][0..out_size];
            const weight_layer =
                self.buffers.weights[weight_base..][0..weight_count];
            const bias_layer =
                self.buffers.biases[bias_base..][0..out_size];

            const activation_forward =
                self.activations[next_layer].forward.?;

            // Calculate the next layer.
            var weight_index: usize = 0;

            for (0..out_size) |out| {
                var sum = bias_layer[out];

                for (input_layer) |in| {
                    const weight = weight_layer[weight_index];
                    sum += in * weight;
                    weight_index += 1;
                }

                output_layer[out] = activation_forward(sum);
            }
        }
    }

    fn calculateOutputDeltas(self: *Self, targets: []const NetType) void {
        const output_layer = self.layer_sizes.len - 1;
        const output_size = self.layer_sizes[output_layer];

        const output_base = self.offsets.layers[output_layer];
        const delta_base = self.offsets.biases[output_layer - 1];

        const outputs =
            self.buffers.neurons[output_base..][0..output_size];
        const deltas =
            self.buffers.deltas[delta_base..][0..output_size];

        const activation_derivative =
            self.activations[output_layer].derivative.?;

        for (outputs, targets, deltas) |output, target, *delta| {
            const @"error" = target - output;
            delta.* = @"error" * activation_derivative(output);
        }
    }

    fn calculateHiddenDeltas(self: *Self) void {
        var layer = self.layer_sizes.len - 2;

        while (layer > 1) : (layer -= 1) {
            const next_layer = layer + 1;

            const current_size = self.layer_sizes[layer];
            const next_size = self.layer_sizes[layer + 1];

            const neuron_base = self.offsets.layers[next_layer];
            const weight_base = self.offsets.weights[next_layer];
            const delta_base = self.offsets.biases[layer];
            const next_delta_base = self.offsets.biases[next_layer];

            const neurons =
                self.buffers.neurons[neuron_base..][0..current_size];
            const deltas =
                self.buffers.deltas[delta_base..][0..current_size];
            const next_deltas =
                self.buffers.deltas[next_delta_base..][0..next_size];
            const weights =
                self.buffers.weights[weight_base..][0 .. current_size * next_size];

            const activation_derivative =
                self.activations[layer + 1].derivative.?;

            // Compute deltas for the current hidden layer
            // using the deltas and weights of the next layer.
            for (0..current_size) |neuron| {
                var weighted_error: NetType = 0;

                for (0..next_size) |next_neuron| {
                    const weight_index = current_size * next_neuron + neuron;
                    weighted_error += next_deltas[next_neuron] * weights[weight_index];
                }

                deltas[neuron] =
                    weighted_error * activation_derivative(neurons[neuron]);
            }
        }
    }

    fn updateBuffers(self: *Self, learning_rate: NetType) void {
        const connection_count =
            self.layer_sizes.len - 1;

        for (0..connection_count) |layer| {
            const in_size = self.layer_sizes[layer];
            const out_size = self.layer_sizes[layer + 1];
            const weight_count = in_size * out_size;

            const input_base = self.offsets.layers[layer];
            const weight_base = self.offsets.weights[layer];
            const bias_base = self.offsets.biases[layer];
            const delta_base = self.offsets.biases[layer];

            const inputs =
                self.buffers.neurons[input_base..][0..in_size];
            const weights =
                self.buffers.weights[weight_base..][0..weight_count];
            const biases =
                self.buffers.biases[bias_base..][0..out_size];
            const deltas =
                self.buffers.deltas[delta_base..][0..out_size];

            // Apply the gradient update to weights and biases.
            var weight_index: usize = 0;

            for (0..out_size) |out| {
                const scaled_delta =
                    deltas[out] * learning_rate;

                for (inputs) |in| {
                    const weight_delta = in * scaled_delta;
                    weights[weight_index] += weight_delta;
                    weight_index += 1;
                }

                biases[out] += scaled_delta;
            }
        }
    }

    fn backpropagate(
        self: *Self,
        targets: []const NetType,
        learning_rate: NetType,
    ) void {
        self.calculateOutputDeltas(targets);
        self.calculateHiddenDeltas();
        self.updateBuffers(learning_rate);
    }

    pub fn train(
        self: *Self,
        inputs: []const NetType,
        targets: []const NetType,
        epochs: usize,
        learning_rate: NetType,
    ) void {
        const input_size = self.layer_sizes[0];
        std.debug.assert(inputs.len % input_size == 0);

        const sample_count = inputs.len / input_size;
        std.debug.assert(sample_count > 0);

        const output_layer = self.layer_sizes.len - 1;
        const output_size = self.layer_sizes[output_layer];
        std.debug.assert(targets.len == output_size * sample_count);

        const progress_step =
            @max(@as(usize, 1), epochs / 1_000);

        for (0..epochs) |epoch| {
            const is_last_epoch = epoch + 1 == epochs;

            if (epoch % progress_step == 0 or is_last_epoch) {
                const progress =
                    @as(NetType, @floatFromInt(epoch + 1)) /
                    @as(NetType, @floatFromInt(epochs)) *
                    100;

                std.debug.print(
                    "[train] \x1b[32m{d:.1}%\x1b[0m | epoch {}/{}\r",
                    .{ progress, epoch + 1, epochs },
                );
            }

            for (0..sample_count) |sample| {
                const input =
                    inputs[input_size * sample ..][0..input_size];
                const target =
                    targets[output_size * sample ..][0..output_size];

                self.forward(input);
                self.backpropagate(target, learning_rate);
            }
        }
    }
};
