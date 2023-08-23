# statsbook

A Swift library to read/write WFTDA Statsbooks.  Note that currently we only support the January 2019 Release.

This is _not_ a general purpose xlsx file reader.  It isn't even a
general purpose ZIP file reader.  It only supports a small subset of
the features (those required by the Statsbook), but it does handle
reclaculating all the values correctly so far.

## TODO:
- Support editing and updating values once edited
- Support recompressing changed files so we can save edited files
- Add nicer UX on top of the various sheets (like the IGRF struct does)
