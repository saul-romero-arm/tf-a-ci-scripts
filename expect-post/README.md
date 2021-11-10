# Post-expect scripts

Post-expect scripts perform checking and validation on the captured logs
of DUT interaction (usually, output from different UARTs). The original
reason for introducing of this type of scripts was the fact that LAVA
couldn't perform test matching on additional communication channels
(e.g. other UARTs than UART0). Instead, it just records output from
them to the logs. And post-expect scripts then can parse these logs
and perform required validation.

From the above description it should be clear that such tests are
passive, i.e. can't inject any input into DUT. However, at the time
of writing, TrustedFirmware worked in exactly this way: the primary
UART could be connected to an interactive shell (Linux command line,
etc.), where input can be accepted, while other UARTs are used for
logging from different subsystems.

Note that these tests are contained in the subdirectory named
`expect-post`, to make that sort together with the original `expect`
directory, to make all variants of expect scripts immediately visible.

## Scripts format

Post-expect scripts are just arbitrary executables (usually shell
or Python scripts), which are passed the name of the log file they
should check (which contain output from a particular UART). A script
should exit with 0 status if the test was successful, and non-zero
otherwise.

Specific execution model is:

For each artefacts/debug/uart<num>/run/expect file (where N is 1, 2,
etc.) the expect script name is read from that file. In ArmCI, that
script would be looked up in tf-a-ci-scripts/expect/ , but in
OpenCI, it's instead looked up tf-a-ci-scripts/expect-post/ . Each
test script is executed in Jenkins, after LAVA job finished execution,
and its log was fetched (and split into per-UART output). A short
summary of total number of executed post-expect scripts is printed at
the end, together with number of failed tests. If any test is failed,
Jenkins job is failing too.
