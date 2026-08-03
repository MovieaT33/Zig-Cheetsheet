@echo off

:loop
zig run .\examples\nn.zig -OReleaseFast

if errorlevel 1 goto loop

pause