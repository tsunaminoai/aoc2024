<!-- gen-readme start - generated by https://github.com/jetify-com/devbox/ -->
## Getting Started
This project uses [devbox](https://github.com/jetify-com/devbox) to manage its development environment.

Install devbox:
```sh
curl -fsSL https://get.jetpack.io/devbox | bash
```

Start the devbox shell:
```sh 
devbox shell
```

Run a script in the devbox environment:
```sh
devbox run <script>
```
## Scripts
Scripts are custom commands that can be run using this project's environment. This project has the following scripts:

* [fast](#devbox-run-fast)
* [safe](#devbox-run-safe)
* [test](#devbox-run-test)

## Shell Init Hook
The Shell Init Hook is a script that runs whenever the devbox environment is instantiated. It runs 
on `devbox shell` and on `devbox run`.
```sh
echo 'Welcome to devbox!' > /dev/null
```

## Packages

* [zig@0.13.0](https://www.nixhub.io/packages/zig)
* [zls@latest](https://www.nixhub.io/packages/zls)
* [watchexec@latest](https://www.nixhub.io/packages/watchexec)

## Script Details

### devbox run fast
```sh
zig build -Doptimize=ReleaseFast run
```
&ensp;

### devbox run safe
```sh
zig build -Doptimize=ReleaseSafe run
```
&ensp;

### devbox run test
```sh
zig build -Doptimize=Debug test
```
&ensp;



<!-- gen-readme end -->
