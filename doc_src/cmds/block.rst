.. _cmd-block:

block - (removed)
==================

Synopsis
--------

.. synopsis::

    block [(--local | --global)]
    block --erase

Description
-----------

The ``block`` builtin was supposed to prevent events triggered by ``fish`` or the :ref:`emit <cmd-emit>` command from being delivered and acted upon while the block is in place.

However, it turned out to be unusable, and so it was removed.

It still exists to tell any users that it no longer exists.

