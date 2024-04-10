const watcher = Deno.watchFs("./");

import { debounce } from "https://deno.land/std@0.207.0/async/debounce.ts";

const argsArray = ["test"];

const tags = Deno.args && Deno.args[0] ? Deno.args[0] : []

if (tags) {
  argsArray.push("--exclude-tags");
  argsArray.push(tags);
}

argsArray.push(".")

const cmd = new Deno.Command(
  "arweave",
  {
    args: argsArray,
  },
);

const runTests = debounce(async () => {
  const runTime = `\Watcher run time: ${new Date().toISOString()}`;
  const output = await cmd.output();

  const decoder = new TextDecoder();

  const err = output.stderr;
  const out = output.stdout;

  if (err) {
    const decoded = decoder.decode(err);
    if (decoded !== "") {
      console.log(decoded);
      console.log(runTime);
      return;
    }
  }

  console.log(decoder.decode(out));

  console.log(runTime);
}, 200);

runTests();

for await (const _event of watcher) {
  runTests();
}
