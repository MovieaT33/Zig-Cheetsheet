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

    fn randomParameter(rand: std.Random) NetType {
        return randomNetValue(rand) * 2 - 1;
    }

    pub fn create(
        topology: []const usize,
        activations: []const Activation,
        allocator: Allocator,
        rand: std.Random,
    ) Allocator.Error!*Self {
        const self = try allocator.create(Self);
        errdefer self.deinit();

        self.allocator = allocator;

        self.layer_sizes =
            try self.allocator.dupe(usize, topology);

        const layer_count = self.layer_sizes.len;
        const connection_count = layer_count - 1;
        self.offsets.layers =
            try self.allocator.alloc(usize, layer_count);
        self.offsets.weights =
            try self.allocator.alloc(usize, connection_count);
        self.offsets.biases =
            try self.allocator.alloc(usize, connection_count);

        var neuron_offset: usize = 0;
        var weight_offset: usize = 0;
        var bias_offset: usize = 0;

        // Compute neuron offsets for each layer.
        for (self.layer_sizes, 0..) |layer_size, layer| {
            self.offsets.layers[layer] = neuron_offset;
            neuron_offset += layer_size;
        }

        // Compute parameter offsets for each layer connection.
        for (0..connection_count) |connection| {
            const in_size = self.layer_sizes[connection];
            const out_size = self.layer_sizes[connection + 1];

            self.offsets.weights[connection] = weight_offset;
            self.offsets.biases[connection] = bias_offset;

            weight_offset += in_size * out_size;
            bias_offset += out_size;
        }

        self.buffers.neurons =
            try self.allocator.alloc(NetType, neuron_offset);
        self.buffers.weights =
            try self.allocator.alloc(NetType, weight_offset);
        self.buffers.biases =
            try self.allocator.alloc(NetType, bias_offset);
        self.buffers.deltas =
            try self.allocator.alloc(NetType, bias_offset);

        self.activations =
            try self.allocator.alloc(Activation, layer_count);

        @memset(self.buffers.neurons, 0);
        @memset(self.buffers.deltas, 0);

        @memcpy(self.activations, activations);

        // Randomly initialize layer parameters.
        for (0..connection_count) |layer| {
            const in_size = self.layer_sizes[layer];
            const out_size = self.layer_sizes[layer + 1];

            const weight_base = self.offsets.weights[layer];
            const bias_base = self.offsets.biases[layer];

            for (0..out_size) |out| {
                for (0..in_size) |in| {
                    const weight_index =
                        weight_base +
                        in_size * out +
                        in;
                    self.buffers.weights[weight_index] = randomParameter(rand);
                }

                const bias_index = bias_base + out;
                self.buffers.biases[bias_index] = randomParameter(rand);
            }
        }

        return self;
    }

    pub fn deinit(self: *Self) void {
        self.allocator.free(self.layer_sizes);

        self.allocator.free(self.buffers.neurons);
        self.allocator.free(self.buffers.weights);
        self.allocator.free(self.buffers.biases);
        self.allocator.free(self.buffers.deltas);

        self.allocator.free(self.offsets.layers);
        self.allocator.free(self.offsets.weights);
        self.allocator.free(self.offsets.biases);

        self.allocator.free(self.activations);

        self.allocator.destroy(self);
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
    }

    pub fn forward(self: *Self, input: []const NetType) void {
        std.debug.assert(input.len == self.layer_sizes[0]);

        @memcpy(
            self.buffers.neurons[0..input.len],
            input,
        );

        const neurons = self.buffers.neurons;
        const weights = self.buffers.weights;
        const biases = self.buffers.biases;

        const connection_count = self.layer_sizes.len - 1;
        for (0..connection_count) |layer| {
            const in_size = self.layer_sizes[layer];
            const out_size = self.layer_sizes[layer + 1];

            const input_base = self.offsets.layers[layer];
            const output_base = self.offsets.layers[layer + 1];

            var weight = self.offsets.weights[layer];
            var bias = self.offsets.biases[layer];

            const activation_forward = self.activations[layer + 1].forward.?;

            for (0..out_size) |out| {
                var sum = biases[bias];

                var in: usize = 0;
                while (in < in_size) : (in += 1) {
                    sum += neurons[input_base + in] * weights[weight];
                    weight += 1;
                }

                neurons[output_base + out] = activation_forward(sum);
                bias += 1;
            }
        }
    }
};
