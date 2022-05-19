string-trim - remove trailing whitespace
========================================

Synopsis
--------

.. BEGIN SYNOPSIS

.. synopsis::

    string trim [-l | --left] [-r | --right] [(-c | --chars) CHARS] [(-M | --matching)]
                [-q | --quiet] [STRING ...]

.. END SYNOPSIS

Description
-----------

.. BEGIN DESCRIPTION

``string trim`` removes leading and trailing whitespace from each *STRING*. If **-l** or **--left** is given, only leading whitespace is removed. If **-r** or **--right** is given, only trailing whitespace is trimmed. The **-c** or **--chars** switch causes the characters in *CHARS* to be removed instead of whitespace. If **-M** or **--matching** is given, characters will only be removed if the same are on both sides of the string, so a prefix is removed if it matches a (reversed) suffix. This allows removing e.g. layers of quotes.


Exit status: 0 if at least one character was trimmed, or 1 otherwise.

.. END DESCRIPTION

Examples
--------

.. BEGIN EXAMPLES

::

    >_ string trim ' abc  '
    abc

    >_ string trim --right --chars=yz xyzzy zany
    x
    zan

    >_ string trim --matching --chars="'" "'this is a quoted string'"
    this is a quoted string

    >_ string trim --matching --chars="'" "'this is not a quoted string"
    'this is a quoted string

    >_ string trim --matching --chars="xX-" "xXx---DEATH xXx ANGEL 666X---xXx"
    DEATH xXx ANGEL 666X

.. END EXAMPLES
