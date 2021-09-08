# Expect Scripts

The project tracks two set of expect scripts under two different folders, `expect` and
`lava-expect`, the former required for local (non-LAVA) or Internal CI (Arm CI) and
the latter for Open CI (LAVA). Note that any contribution into the expect scripts
**must be done in both folders**, otherwise expect test coverage will differ.

## LAVA Test Actions

The `lava-expect` script does exactly the same as its counterpart under the `expect`
folder. However, LAVA would use either [Interactive Test Actions](https://validation.linaro.org/static/docs/v2/actions-test.html#interactive-test-action)
or [Monitor Test Actions](https://validation.linaro.org/static/docs/v2/monitors.html) to
support possible scenarios. In other words, expect scripts are transformed into either
interactive or monitor test actions.

In the `lava-expect` scripts, both types of actions, interactive and monitor, are defined
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

To better understand how `expect` scripts translates into `lava-expect`, we can compare similar
scripts, i.e. `expect/disable_dyn_auth_tftf.exp` versus `lava-expect/disable_dyn_auth_tftf.exp` which only requires interactive
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

* and its counterpart `lava-expect/disable_dyn_auth_tftf.exp` (note, the same filename but different folder)

```
source $ci_root/lava-expect/disable_dyn_auth.inc

prompt='Booting trusted firmware test framework'
successes='Running at NS-EL(1|2)'
expect_string+=("i;${prompt};${successes}")

prompt='Tests Failed  : 0'
successes='Exiting tests.'
failures='Tests Passed  : 0'
expect_string+=("i;${prompt};${successes};${failures}")
```

The first thing to notice is that all strings are literal (no regex is required) and each are expected
just once, so interactive actions are the choice.

As seen, the same *expect strings* appears in both, but in case of `lava-expect/disable_dyn_auth_tftf.exp`,
is it written in *bash* language and **appending** elements into `expect_string`, which is the variable
that ultimately is transformed into interactive test actions by CI scripts.

It is worth noting that each *expect string* **must be** appended `+=` as an
**array element** of `expect_string`, otherwise, and assignment operator `=` would remove
previous defined expect strings. Also note the leading **`i`** character in the array element,
indicating a interactive actions.

As indicated above, interactive actions match strings in a specific **order** with a **pass/fail
criteria**. For the above example, the first expected match is called the `prompt` (in LAVA terms),
and following it, the passing criteria is defined through the `successes` variable and the failing
criteria through `failures` variable, defining these at the appended `expect_string` element:

```
prompt='Tests Failed  : 0'
successes='Exiting tests.'
failures='Tests Passed  : 0'
expect_string+=("i;${prompt};${successes};${failures}")
```

Each *interactive action string* must follow a certain syntax as seen in the above example

```
expect_string+=("i;${prompt};${successes};${failures}")
```

In general, we first match the `prompt`, then after `prompt`,
match `successes` and `failures` for pass/fail strings. In case different strings
define the pass/fail criteria, these can be separated with a `@` character:

```
prompt='A'
successes='B@C'
failures='D@E'
expect_string+=("${prompt};${successes};${failures}")
```

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

which is translated into `lava-expect/linux-tpm.exp`

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
