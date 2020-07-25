# RUN: %fish %s

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
