import dob;

import std.stdio;

int main(string[] args)
{
    buildSelf(args, ["build.d", "dob.d"]);

    bool success = Project("dob")
        .setCompiler("ldc2")
        .addFiles(["build.d", "dob.d"])
        .addFlags(["-O"])
        .invoke();

    if (!success) {
        writeln("Build failed!");
        return 1;
    }

    writeln("Build complete!");
    return 0;
}