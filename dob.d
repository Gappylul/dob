module dob;

import std.stdio;
import std.process;
import std.format;
import std.file;
import std.datetime;
import core.stdc.stdlib;

public import std.process : spawnProcess, wait;

bool needsRebuild(string outPath, string[] inPaths)
{
    if (!exists(outPath)) return true;
    SysTime ignore, outMod;
    getTimes(outPath, ignore, outMod);

    foreach (inPath; inPaths) {
        if (!exists(inPath)) continue;
        SysTime inMod;
        getTimes(inPath, ignore, inMod);
        if (inMod > outMod) return true;
    }
    return false;
}

void buildSelf(string[] args, string[] sourcePaths)
{
    string binaryPath = args[0];
    if (!needsRebuild(binaryPath, sourcePaths)) return;

    writeln("[dob] Build script changed. Recompiling...");
    string oldPath = format("%s.old", binaryPath);
    if (exists(binaryPath)) rename(binaryPath, oldPath);

    string[] cmd = ["ldc2", format("-of=%s", binaryPath)] ~ sourcePaths;
    auto pid = spawnProcess(cmd);
    if (wait(pid) != 0) {
        if (exists(oldPath)) rename(oldPath, binaryPath);
        exit(1);
    }
    if (exists(oldPath)) remove(oldPath);

    writeln("[dob] Restarting with new binary...\n");
    execvp(binaryPath, args);
    exit(0);
}

struct Project {
    string name;
    string compiler = "clang++";
    string[] files;
    string[] flags;
    string[] libs;

    this(string name) { this.name = name; }

    auto setCompiler(string c) { compiler = c; return this; }
    auto addFiles(string[] f) { files ~= f; return this; }
    auto addFlags(string[] f) { flags ~= f; return this; }
    auto linkLibs(string[] l) { libs ~= l; return this; }

    bool invoke() {
        string[] cmdArgs = [compiler];
        cmdArgs ~= flags;
        cmdArgs ~= files;

        if (compiler == "ldc2" || compiler == "dmd") {
            cmdArgs ~= format("-of=%s", name);
        } else {
            cmdArgs ~= format("-o=%s", name);
        }

        foreach(lib; libs) {
            cmdArgs ~= format("-l%s", lib);
        }

        writeln("[dob] Running: ", cmdArgs);
        return wait(spawnProcess(cmdArgs)) == 0;
    }
}