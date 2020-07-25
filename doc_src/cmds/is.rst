.. _cmd-is:

is - check conditions on files, numbers and text
================================================

Synopsis
--------

::

    is empty STRINGS...
    is notempty STRINGS...
    is same STRINGS...
    is number STRINGS...
    is path PATHS...
    is file PATHS...
    is directory PATHS...
    is link PATHS...
    is readable PATHS...
    is writable PATHS...
    is executable PATHS...
    is equal NUMBERS...
    is greater NUMBERS...
    is greater-equal NUMBERS...
    is less NUMBERS...
    is less-equal NUMBERS...

Description
-----------

``is`` checks if conditions are true. It operates on lists of arguments. The first argument is the command.

A missing or unknown command is an error.

All commands except ``empty`` return false if no argument was passed.

Unlike ``test``, ``is`` does not support logical operators and lacks some negated forms. Use :ref:`combiners <combiners>` and multiple calls to ``is`` instead.

``is`` prints the help when given ``-h`` or ``--help` as the first argument.

String commands
---------------

- ``empty`` checks if all given strings are empty. This returns true if no string was given.
- ``notempty`` checks if all given strings are notempty.
- ``same`` checks if all the given strings are the same. This returns false if only one string was given.
- ``number`` checks if all the given strings are numbers that ``is`` understands. See :ref:`Number commands <cmd-is-numbers>` for more details.

To check if any string is not empty, negate the ``is`` instead: ``not is empty "" "" "foo"`` will be true.

To check if a string has one of a number of given values, use :ref:`contains <cmd-contains>`: ``contains -- foo bar foo baz``.

File and directory commands
---------------------------

- ``path`` checks if all given paths exist.
- ``file`` checks if all given paths are regular files.
- ``directory`` checks if all given paths are directories.
- ``link`` checks if all given paths are symbolic links.
- ``readable`` checks if all given paths are readable.
- ``writable`` checks if all given paths are writable.
- ``executable`` checks if all given paths are executable.

.. _cmd-is-numbers:

Number commands
---------------

``is`` can compare floating point numbers. The radix character is ``.``, not dependent on locale.

All of these commands return false if less than two numbers were given. A number isn't equal to, greater than or less than nothing.

- ``equal`` checks if all given numbers are numerically equal - unlike ``same``, this ignores leading zeroes and trailing zeroes after a "." and can handle hexadecimal numbers with ``0x``.
- ``greater`` checks if every number is greater than the next, i.e. the numbers are in strictly descending order.
- ``less`` checks if every number is smaller than the next, i.e. they are in strictly ascending order.
- ``greater-equal``, like ``greater``, but also true if the numbers are equal.
- ``less-equal``, like ``less``, but also true if the numbers are equal.

The command names are chosen after the operator that would be put between the operands, so::

  is greater 2 1 # compares 2 > 1
  is less 1 2 3 4 5 # compares 1 < 2 < 3 < 4 < 5

Examples
--------

From __fish_complete_docutils::

  if is same $cmd rst2html5
      complete -x -c $cmd -l table-style -a "borderless booktabs align-left align-center align-right colwidths-auto" -d "Specify table style"

From fish_vi_cursor::
  
  # With test - this:
  # - needs to test if $KONSOLE_VERSION is non-empty before checking if it's greater
  # - needs to quote $KONSOLE_VERSION because `test -n` is *true*
  # - still errors out if $KONSOLE_VERSION is non-numeric
  not test -n "$KONSOLE_VERSION" -a "$KONSOLE_VERSION" -ge 200400

  # With is - no error when the argument is not numeric or missing.
  not is greater $KONSOLE_VERSION 200400

From __fish_complete_man::

  if test -z "$section" -o "$section" = 1

  if is empty $section; or is same $section 1


  if test -z "$token" -a "$section" != "[^)]*"

  if is empty $token; and not is same $section "[^)]*"

__fish_md5::

  # Note: This either needs to be quoted or needs to have been checked beforehand.
  if test $argv[1] = -s

  if is same $argv[1] -s

  if is = $argv[1] -s

oh-my-fish/oh-my-fish/pkg/omf/omf.update.fish::

  # Will error out if $OMF_PATH, $OMF_CONFIG or $name aren't set
  if test \( -e $OMF_PATH/themes/$name \) -o \( -e $OMF_CONFIG/themes/$name \)

  # Will just be false if they are unset
  if is path $OMF_PATH/themes/$name; or is path $OMF_CONFIG/themes/$name

Ideas
-----

- Version comparison using ``vercmp``
- ``is true`` - check if a value is "truthy" - number greater than 0, a string like "ON" or "true".
- ``is number`` - check if the value is a number.
- ``--any``, before the command, to return true if any value is true.
- Remove ``notempty``? Add ``notequal``?
- Other names for numeric commands? ``=``?
- Allow the test option naming, possibly as an alternative? "lt"/"le"/"gt"/"ge"?
- ``is prefix``, checking if the first argument is prefix of all the others? (same for suffix etc)

Unimplemented bits:

Some operators for files that nobody really uses much
-----------------------------------------------------

- ``-b FILE`` returns true if ``FILE`` is a block device.

- ``-c FILE`` returns true if ``FILE`` is a character device.

- ``-g FILE`` returns true if ``FILE`` has the set-group-ID bit set.

- ``-G FILE`` returns true if ``FILE`` exists and has the same group ID as the current user.

- ``-k FILE`` returns true if ``FILE`` has the sticky bit set. If the OS does not support the concept it returns false. See https://en.wikipedia.org/wiki/Sticky_bit.

- ``-O FILE`` returns true if ``FILE`` exists and is owned by the current user.

- ``-p FILE`` returns true if ``FILE`` is a named pipe.

- ``-s FILE`` returns true if the size of ``FILE`` is greater than zero.

- ``-S FILE`` returns true if ``FILE`` is a socket.

- ``-t FD`` returns true if the file descriptor ``FD`` is a terminal (TTY).

- ``-u FILE`` returns true if ``FILE`` has the set-user-ID bit set.

Operators to compare and examine numbers
----------------------------------------

- ``NUM1 -ne NUM2`` returns true if ``NUM1`` and ``NUM2`` are not numerically equal.

Operators to combine expressions
--------------------------------

- ``COND1 -a COND2`` returns true if both ``COND1`` and ``COND2`` are true.

- ``COND1 -o COND2`` returns true if either ``COND1`` or ``COND2`` are true.

Expressions can be inverted using the ``!`` operator:

- ``! EXPRESSION`` returns true if ``EXPRESSION`` is false, and false if ``EXPRESSION`` is true.

Expressions can be grouped using parentheses.

- ``( EXPRESSION )`` returns the value of ``EXPRESSION``.

 Note that parentheses will usually require escaping with ``\(`` to avoid being interpreted as a command substitution.
