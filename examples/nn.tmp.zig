    const EvolutionConfig = struct {
        population_size: usize,
        generations: usize,
        mutation_strength: NetType,
        mutation_rate: NetType,
    };
    fn evolve(
        self: *Self,
        inputs: []const []const NetType,
        targets: []const []const NetType,
        config: EvolutionConfig,
        rand: std.Random,
    ) !void {
        var population = try self.allocator.alloc(
            *Self,
            config.population_size,
        );
        defer {
            for (population) |network|
                network.deinit();

            self.allocator.free(population);
        }

        for (population) |*network| {
            network.* = try self.clone(rand);
            network.*.copyParameters(self);
            network.*.mutate(
                1,
                1,
                rand,
            );
        }

        const progress_step = @max(1, config.generations / 1_000);
        var best_loss: NetType = std.math.inf(NetType);

        for (0..config.generations) |generation| {
            var best = population[0];
            best_loss = best.lossMseDataset(inputs, targets);

            for (population[1..]) |network| {
                const loss = network.lossMseDataset(inputs, targets);

                if (loss < best_loss) {
                    best = network;
                    best_loss = loss;
                }
            }

            self.copyParameters(best);

            // check if the loss is too high after 50 generations, if so, return an error
            if (generation == 50 and best_loss > 0.0001)
                return error.LossTooHigh;

            if (best_loss == 0) {
                std.debug.print("\nevolution finished early\n", .{});
                break;
            }

            if (generation % progress_step == 0 or generation + 1 == config.generations) {
                const progress =
                    @as(NetType, @floatFromInt(generation + 1)) /
                    @as(NetType, @floatFromInt(config.generations)) * 100;

                std.debug.print(
                    "train/evolution: \x1b[32m{d:.1}%\x1b[0m | generation {}/{} | loss: {d:.20}\r",
                    .{
                        progress,
                        generation + 1,
                        config.generations,
                        best_loss,
                    },
                );
            }

            for (population, 0..) |network, index| {
                network.copyParameters(best);

                if (index == 0)
                    continue;

                network.mutate(
                    config.mutation_rate,
                    config.mutation_strength,
                    rand,
                );
            }
        }
    }
};

    const final_loss = nn.lossMseDataset(&inputs, &targets);
    var zeros: usize = 0;
    if (final_loss > 0) {
        var x = @abs(final_loss);
        while (x < 1) {
            x *= 10;

            if (x < 1) {
                zeros += 1;
            } else {
                break;
            }
        }
    }

    std.debug.print(
        "\x1b[1mmse loss\x1b[0m: \x1b[31;1m{d:.20}\x1b[0m ({} zeros)\n",
        .{ final_loss, zeros },
    );
}
