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

    // Train and refine the network.
    const inputs = [_]NetType{
        0.5, 0.5,
        0.1, 0.1,
    };
    const targets = [_]NetType{
        0.5,
        0.1,
    };

    network.train(&inputs, &targets, 1_000_000, 0.05);
    network.train(&inputs, &targets, 1_000_000, 0.01);
    network.train(&inputs, &targets, 1_000_000, 0.001);

    try network.evolve(&inputs, &targets, .{
        .population_size = 100,
        .elite_count = 10,
        .generations = 10_000,
        .mutation_rate = 0.05,
        .mutation_strength = 0.005,
    }, rand);
    try network.evolve(&inputs, &targets, .{
        .population_size = 10_000,
        .elite_count = 1_000,
        .generations = 100_000,
        .mutation_rate = 0.1,
        .mutation_strength = 0.000001,
    }, rand);
    try network.evolve(&inputs, &targets, .{
        .population_size = 1_000,
        .elite_count = 10,
        .generations = 100_000,
        .mutation_rate = 0.05,
        .mutation_strength = 0.0000001,
    }, rand);
}
