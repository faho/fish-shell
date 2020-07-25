# RUN: %fish %s

# Confirm all subcommands except for "empty" return false if given no arguments

for cmd in notempty same path file directory link readable writable executable equal {greater,less}{,-equal}
    is $cmd; and echo ERROR: $cmd returns true!!!!
    # No check here.
end

is same 01 1
echo $status
# CHECK: 1
is equal 01 1
echo $status
# CHECK: 0
is greater 5 4 3 2 1
echo $status
# CHECK: 0
is greater 5 4 4 2 1
echo $status
# CHECK: 1
is greater-equal 5 4 4 2 1
echo $status
# CHECK: 0

is less 3 2 1
echo $status
# CHECK: 1
is less 1 2 3
echo $status
# CHECK: 0

is same foo foo foo foo
echo $status
# CHECK: 0
is same foo bar baz
echo $status
# CHECK: 1
is empty
echo $status
# CHECK: 0
is notempty
echo $status
# CHECK: 1
is notempty "" "" ""
echo $status
# CHECK: 1
is empty "" "" ""
echo $status
# CHECK: 0
is empty "" "" "" foo
echo $status
# CHECK: 1

is greater inf 5
echo inf $status
# CHECK: inf 1

is greater nan 3
echo nan $status
# CHECK: nan 1

set -l dir (mktemp -d)
touch $dir/file

is path $dir/file
echo $status
# CHECK: 0
is file $dir/file
echo $status
# CHECK: 0
is path $dir/nonexistent
echo $status
# CHECK: 1
is file $dir/nonexistent
echo $status
# CHECK: 1

ln -s $dir/file $dir/link
is link $dir/link
echo $status
# CHECK: 0
is file $dir/link
echo $status
# CHECK: 0
is directory $dir/link
echo $status
# CHECK: 1

is directory $dir
echo $status
# CHECK: 0

is writable $dir
echo $status
# CHECK: 0

is executable $dir/file
echo $status
# CHECK: 1
chmod +x $dir/file
is executable $dir/file
echo $status
# CHECK: 0

is notacommand argument argument
# CHECKERR: is: Subcommand 'notacommand' is not valid

is number 253.123
echo $status
# CHECK: 0
is number 0xc0ffee
echo $status
# CHECK: 0
is number 0xCAFE
echo $status
# CHECK: 0
