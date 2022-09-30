# LAVA Expectation Scripts

This repository contains two sets of scripts under two different folders - `expect` and
`expect-lava` -  which specify the expected UART output of tests run on the on-premises CI, and
OpenCI. The on-premises CI utilizes the `expect` utility to test UART output from FVP jobs, whilst
OpenCI utilizes LAVA in all cases (both CIs utilize LAVA for physical board tests).

To aid with migration from the on-premises CI to OpenCI, expectations in `expect-lava` may be
written in Bash utilizing a set of common Bash infrastructure designed to emulate `expect`'s
functionality. These scripts end with `.exp`, and the infrastructure is described in the next
section.

Alternatively, test fragments may be written directly in LAVA's test description format, documented
[here][1]. These expectations will be picked up if the file ends in `.yaml` and there is no
corresponding `.exp` file. These files may contain Bash expressions (such as variable expansion).

Note that any contribution into the expect scripts **must be done in both folders**, otherwise test
expectations will differ.

[1]: https://validation.linaro.org/static/docs/v2/developing-tests.html

## LAVA Test Actions

The `expect-lava` script does exactly the same as its counterpart under the `expect`
folder. However, LAVA would use either [Interactive Test Actions](https://validation.linaro.org/static/docs/v2/actions-test.html#interactive-test-action)
or [Monitor Test Actions](https://validation.linaro.org/static/docs/v2/monitors.html) to
support possible scenarios. In other words, expect scripts are transformed into either
interactive or monitor test actions.

In the `expect-lava` scripts, both types of actions, interactive and monitor, are defined
using the same array variable, `expect_string` but each array element would contain either
a leading `i` indicating interactive actions or `m` indicating monitor actions.


Interactive actions are used in the following scenarios

* Matching a literal and single-event string, i.e. matching `Booting Trusted Firmware`
* Matching literal string in strict order of appearance, i.e. matching `BL1: Booting BL31`
after `BL1: Booting BL2`
* Matching literal string, a prompt, following a pass/fail criteria
* Input commands at the bootloader or command prompt

Monitor actions are used in the following scenario

* regex matching through the log, i.e. 'Digest(\s|\w):\s(\w{2}\s){16}'.

The following sections go in detail providing syntactic details for each scenario.

### Interactive Actions Strings

To better understand how `expect` scripts translates into `expect-lava`, we can compare similar
scripts, i.e. `expect/disable_dyn_auth_tftf.exp` versus `expect-lava/disable_dyn_auth_tftf.exp` which only requires interactive
actions. Let's compare these two:

* `expect/disable_dyn_auth_tftf.exp`

```
source [file join [file dirname [info script]] disable_dyn_auth.inc]

expect_string "Booting trusted firmware test framework" "Starting TFTF"
expect_re "Running at NS-EL(1|2)"

expect {
	"Tests Failed  : 0" {
		expect_string "Exiting tests." "<<TFTF Success>>"
		exit_uart 0
	}
	"Tests Passed  : 0" {
		puts "<<TFTF no tests passed>>"
		exit_uart -1
	}
	-re "Tests Failed  : \[^0]" {
		puts "<<TFTF Fail>>"
		exit_uart -1
	}
	timeout {
		exit_timeout
	}
}

exit_uart -1
```

* and its counterpart `expect-lava/disable_dyn_auth_tftf.exp` (note, the same filename but different folder)

```
source $ci_root/expect-lava/disable_dyn_auth.inc

prompt='Booting trusted firmware test framework'
expect_string+=("i;${prompt}")

prompt='Running at NS-EL(1|2)'
expect_string+=("i;${prompt}")

prompt='Tests Failed  : 0'
expect_string+=("i;${prompt}")

prompt='Exiting tests.'
failures='Tests Passed  : 0'
expect_string+=("i;${prompt};;${failures}")
```

The first thing to notice is that all strings are literal (no regex is required) and each are expected
just once, so interactive actions are the choice.

As seen, the same *expect strings* appears in both, but in case of `expect-lava/disable_dyn_auth_tftf.exp`,
is it written in *bash* language and **appending** elements into `expect_string`, which is the variable
that ultimately is transformed into interactive test actions by CI scripts.

It is worth noting that each *expect string* **must be** appended `+=` as an
**array element** of `expect_string`, otherwise, and assignment operator `=` would remove
previous defined expect strings. Also note the leading **`i`** character in the array element,
indicating a interactive actions.

As indicated above, interactive actions match strings in a specific **order**.
For the above example, expect strings are matched setting the `prompt` and an optional
`failures` value, the latter indicating a possible failure string.

*Interactive action strings* should follow the following syntax

```
expect_string+=("i;<prompts>[;<successes>;<failures>;<commands>]")
```

Indicating the `prompts` to match, which can be one or several separated by the `@` char and
optional `successeses`, `failures` and `commands` strings.

One good way to explain (or at least understand it) is: If expect_string has a format of `i;<expected>`,
then output will be matched for `<expected>` (until the end of output or timeout, lack of match is a
failure in either case). Otherwise, the format is: `i;<prompts>;[<successeses>];[<failures>];[<commands>]`;
a `<command>` will be sent to DUT, if specified; any output will be matched until next `<prompts>`;
if `<successes>` is specified, it must be matched **before** appearance of prompt for this testcase
to be successful (if `<successes>` is not matched before prompt, it's a failure); alternatively,
if `<failures>` is matched, it's a fast-track failure (otherwise the lack of success output is
enough to record a failure).

Again, this prompts/successes/failures form makes a good sense if actively sending a `<command>`
and much less sense if not sending any `<command>`. Between these 2 main forms: *passively* matching output
vs *actively* sending a command to a shell and checking its results, there can be other use cases
which can be encoded with the full form, but then those would be corner/niche cases most of the cases.

### Monitor Action Strings

If the corresponding expect string is a regular expression, a *regex* and/or input commands,  one should
use LAVA [Monitor Test Actions](https://validation.linaro.org/static/docs/v2/monitors.html). Besides the
regex strings, monitors requires a start and end strings.

As in the previous section, it is best if understood with a real example, the `expect/linux-tpm.exp`

```
set non_zero_pcr "(?!(\\s00){16})((\\s(\[0-9a-f\]){2}){16}\\s)"

expect {

        -re "Digest(\\s|\\w)*:\\s(\\w{2}\\s){16}|\
        : (\\w{2}\\s){16}|\
        Event(\\s|\\w)*:\\s\\w+\\s" {
                puts $digest_log $expect_out(0,string)
                exp_continue
        }

        -exact "Booting BL31" {
                close $digest_log
        }

        timeout {
                exit_timeout
        }
}

expect {
        "login" {
                send "root\n"
        }

        timeout {
                exit_timeout
        }
}

expect {
        "#" {
                # Load the fTPM driver and retrieves PCR0
                send "ftpm\n"
        }

        timeout {
                exit_timeout
        }
}

for {set i 1} {$i < 11} {incr i} {
        send "pcrread -ha $i\n"

        expect {
                -re "(\\s00){16}\\s+(00\\s){16}" { }

                -re $non_zero_pcr {
                        exit_uart -1
                }

                timeout {
                        exit_timeout
                }
        }
}
```

which is translated into `expect-lava/linux-tpm.exp`

```
non_zero_pcr='(?!(\s00){16})((\s([0-9a-f]){2}){16}\s)'

expect_string+=('m;Booting Trusted Firmware;Booting BL31;Digest(\s|\w)*:\s(\w{2}\s){16}@: (\w{2}\s){16}@Event(\s|\w)*:\s\w+\s')

expect_string+=('i;buildroot login:')

expect_string+=("i;#;${non_zero_pcr};;root@ftpm")

zero_pcr="(\s00){16}\s+(00\s){16}"
for i in $(seq 1 11); do
    expect_string+=("i;#;${zero_pcr};;pcrread -ha $i")
done
```

In this case, translation required monitor and interactive strings. For the monitor strings, this is the syntax

```
expect_string+=('<start match>;<end match>;<regex 1>@<regex 2>@...')
```
