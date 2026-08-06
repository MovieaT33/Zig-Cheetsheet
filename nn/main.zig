const std = @import("std");

const activation = @import("activation.zig");
const none = activation.None.activation;
const linear = activation.Linear.activation;
const relu = activation.ReLU.activation;
const sigmoid = activation.Sigmoid.activation;
const Activation = activation.Activation;

const NetType = @import("config.zig").NetType;
const NeuralNetwork = @import("nn.zig").NeuralNetwork;

pub fn main(init: std.process.Init) !void {
    var gpa = std.heap.DebugAllocator(.{
        .safety = true,
        .enable_memory_limit = true,
        .verbose_log = true,
    }){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    const now = std.Io.Timestamp.now(init.io, .real);
    const seed = now.toNanoseconds();
    var prng = std.Random.DefaultPrng.init(@intCast(seed));
    const rand = prng.random();

    // Define the topology and activation functions for the neural network.
    const topology = [_]usize{ 2, 3, 1 };
    const activations = [_]Activation{
        none,
        relu,
        sigmoid,
    };

    // Initialize the neural network.
    const network = try NeuralNetwork.init(
        &topology,
        &activations,
        allocator,
        rand,
    );
    defer network.deinit();

    // Example input for the neural network.
    const input = [_]NetType{ 0.5, -0.25 };
    network.forward(&input);

    const last_layer = network.layer_sizes.len - 1;
    const last_layer_size = network.layer_sizes[last_layer];
    const output_offset = network.offsets.layers[last_layer];
    const output = network.buffers.neurons[output_offset .. output_offset + last_layer_size];

    std.debug.print("output: {any}\n", .{output});
    std.log.info("total requested: {} bytes", .{gpa.total_requested_bytes});
}
