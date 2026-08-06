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
    const output_layer = network.layer_sizes.len - 1;
    const output_layer_size = network.layer_sizes[output_layer];
    const output_base = network.offsets.layers[output_layer];
    const output = network.buffers.neurons[output_base..][0..output_layer_size];

    const inputs = [_]NetType{
        0.5, 0.5,
        0.1, 0.1,
    };
    const targets = [_]NetType{
        0.5,
        0.1,
    };

    std.debug.print(
        "output: {any} | loss: {}\n",
        .{ output, network.calculateMse(&inputs, &targets, 2) },
    );

    network.train(&inputs, &targets, 2, 10_000, 0.05);

    std.debug.print(
        "output: {any} | loss: {}\n",
        .{ output, network.calculateMse(&inputs, &targets, 2) },
    );
}
