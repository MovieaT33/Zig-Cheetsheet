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
            const bias_count = out_size;

            const weight_layer =
                self.buffers.weights[self.offsets.weights[layer] .. self.offsets.weights[layer] + weight_count];
            const bias_layer =
                self.buffers.biases[self.offsets.biases[layer] .. self.offsets.biases[layer] + bias_count];

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

    fn allocateOffsets(self: *Self) Allocator.Error!void {
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

    fn allocateParameters(
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
            try self.allocator.alloc(NetType, layout.biases); // Deltas have the same size as biases.

        self.activations =
            try self.allocator.alloc(
                Activation,
                self.layer_sizes.len,
            );
    }

    fn initializeState(self: *Self, activations: []const Activation) void {
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

        try self.allocateOffsets();

        const layout = self.calculateLayout();

        try self.allocateParameters(layout);

        self.initializeState(activations);

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
        return try Self.create(
            self.layer_sizes,
            self.activations,
            self.allocator,
            rand,
        );
    }

    pub fn copyParameters(self: *Self, source: *const Self) void {
        std.debug.assert(self.buffers.weights.len == source.buffers.weights.len);
        std.debug.assert(self.buffers.biases.len == source.buffers.biases.len);

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
        sample_count: usize,
    ) NetType {
        std.debug.assert(sample_count > 0);

        const output_layer = self.layer_sizes.len - 1;

        const input_size = self.layer_sizes[0];
        std.debug.assert(inputs.len == input_size * sample_count);

        const output_size = self.layer_sizes[output_layer];
        std.debug.assert(targets.len == output_size * sample_count);

        const output_base = self.offsets.layers[output_layer];
        const output =
            self.buffers.neurons[output_base .. output_base + output_size];

        const inverse_output_size =
            1 / @as(NetType, @floatFromInt(output_size));
        const inverse_sample_count =
            1 / @as(NetType, @floatFromInt(sample_count));

        var total_loss: NetType = 0;

        for (0..sample_count) |sample| {
            const input_base = sample * input_size;
            const target_base = sample * output_size;

            const input =
                inputs[input_base .. input_base + input_size];
            const target =
                targets[target_base .. target_base + output_size];

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

    pub fn forward(self: *Self, input: []const NetType) void {
        std.debug.assert(input.len == self.layer_sizes[0]);

        // Copy the input values into the first layer of neurons.
        @memcpy(
            self.buffers.neurons[0..input.len],
            input,
        );

        const connection_count = self.layer_sizes.len - 1;
        for (0..connection_count) |layer| {
            const next_layer = layer + 1;

            const in_size = self.layer_sizes[layer];
            const out_size = self.layer_sizes[next_layer];
            const weight_count = in_size * out_size;
            const bias_count = out_size;

            const input_layer =
                self.buffers.neurons[self.offsets.layers[layer] .. self.offsets.layers[layer] + in_size];
            const output_layer =
                self.buffers.neurons[self.offsets.layers[next_layer] .. self.offsets.layers[next_layer] + out_size];
            const weight_layer =
                self.buffers.weights[self.offsets.weights[layer] .. self.offsets.weights[layer] + weight_count];
            const bias_layer =
                self.buffers.biases[self.offsets.biases[layer] .. self.offsets.biases[layer] + bias_count];

            const activation_forward = self.activations[next_layer].forward.?;

            // Compute the next layer.
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
};
