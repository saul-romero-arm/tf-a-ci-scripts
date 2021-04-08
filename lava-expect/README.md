# Expect Scripts

The project tracks two set of expect scripts under two different folders, `expect` and
`lava-expect`, the former required for local (non-LAVA) or Internal CI (Arm CI) and
the latter for Open CI (LAVA). Note that any contribution into the expect scripts
**must be done in both folders**, otherwise expect test coverage will differ.

# LAVA Expect Scripts

The `lava-expect` script does exactly the same as its counterpart under the `expect`
folder. However, LAVA uses [Test Interactive Actions](https://validation.linaro.org/static/docs/v2/actions-test.html#interactive-test-action)
where it expects success or failure strings. The CI would take these `lava-expect`
scripts and converted into LAVA Test Interactive Actions, so the only task on these files is to define either successes
or failures strings and probably the order of appearance.

To better understand how `expect` scripts translates into `lava-expect`, we can compare similar
scripts, i.e. `expect/cactus.exp` vesus `lava-expect/cactus.exp`. Let's compare these two:

* `expect/cactus.exp`

```
.
.
source [file join [file dirname [info script]] handle-arguments.inc]

expect_string "Booting test Secure Partition Cactus"

source [file join [file dirname [info script]] uart-hold.inc]
```

* and its counterpart `lava-expect/cactus.exp` (note, the same filename but different folder)

```
.
.
expect_string+=("Booting test Secure Partition Cactus")

source $ci_root/lava-expect/uart-hold.inc
```

As seen, the same *expect string* appears in both, but in case
of `lava-expect/cactus.exp`, which is written in bash, the variable to be
used is `expect_string` and its *expect string* **must be** appended (`+=`) as an
**array element**. Appending is important, otherwise previous *expect strings* would be
replaced by the assigment (`=`).

In case we want to indicate the **order** of expected scripts and the **pass/fail
criteria**, the *expect string* syntax is a bit more complex but with a few examples,
it can be quickly understood.

For example, in an hypothetical scenario, we want to first match A, then after A,
match B or C for success and match D or E for failures. This would be the `lava-expect`
definition script (to be located under `lava-expect` folder)

```
prompt='A'
successes='B@C'
failures='D@E'
expect_string+=("${prompt};${successes};${failures}")
```

As you can see, `prompt` defines the first match, in this case `A`, then `successes` defines
possible success strings, in this case `B` and `C`, separated by `@` sign, and the same
pattern applies for failure strings, but in this case, matching these would tell LAVA
to fail the job.

For a real examples, compare similar scripts (the same filename) in both expect folders.
