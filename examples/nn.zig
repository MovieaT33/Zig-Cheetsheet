const NeuralNetwork = struct {
    const EvolutionConfig = struct {
        population_size: usize,
        generations: usize,
        mutation_strength: NetType,
        mutation_rate: NetType,
    };
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
