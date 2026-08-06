const std = @import("std");
const testing = std.testing;
const NetType = @import("config.zig").NetType;

const ActivationFunction = *const fn (input: NetType) NetType;
const ActivationDerivative = *const fn (output: NetType) NetType;

pub const Activation = struct {
    forward: ?ActivationFunction,
    derivative: ?ActivationDerivative,
};

pub const None = struct {
    pub const activation = Activation{
        .forward = null,
        .derivative = null,
    };
};

pub const Linear = struct {
    pub const activation = Activation{
        .forward = forward,
        .derivative = derivative,
    };

    fn forward(input: NetType) NetType {
        return input;
    }

    fn derivative(_: NetType) NetType {
        return 1;
    }
};

pub const ReLU = struct {
    pub const activation = Activation{
        .forward = forward,
        .derivative = derivative,
    };

    fn forward(input: NetType) NetType {
        return if (input > 0) input else 0;
    }

    fn derivative(output: NetType) NetType {
        return if (output > 0) 1 else 0;
    }
};

pub const Sigmoid = struct {
    pub const activation = Activation{
        .forward = forward,
        .derivative = derivative,
    };

    fn forward(input: NetType) NetType {
        return 1 / (1 + std.math.exp(-input));
    }

    fn derivative(output: NetType) NetType {
        return output * (1 - output);
    }
};
