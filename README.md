# statsbook

A Swift library to read/write WFTDA Statsbooks.  Note that currently we only support the January 2019 Release.

This is _not_ a general purpose xlsx file reader.  It isn't even a
general purpose ZIP file reader.  It only supports a small subset of
the features (those required by the Statsbook), but it does handle
reclaculating all the values correctly so far.

It does, however, provides a way to take the raw spreadsheet and provide
"covers" over various sheets (and areas in the sheet) to access type
safe information (for example, the home team name as a string from the
IGRF, or the total number of penalties for a given team/period from the
penalty sheet).


# TODO:
- Better handling of times/dates
- Support for points scored on initial trip (in overtime jams) as a separate value
- Support for more than 10 trips

## statsbookJSON
The statsbookJSON module is all the entered data found in the statsbook
as a JSON file.  It does not include anything that should be calculated
by a formula in a "correct" statsbook, as well as some of the totals
found for various places (these are effectively "read only" values).
It is designed to be minimal and mimick the layout of the Statsbook spreadsheet

The JSON generated can include optional comments - by default, for a cell
with no comment the value will be stored as expected.  If there is
a comment associated with the cell the value will actually be an object
with a `comment` (as a string) and a `value` (as whatever the value
actually is).  There is a flag in the encoder to remove comments.  Note
that the JSON file also include a metadata flag that indicates if
comments are used or not, so non-comment supporting reader can
return an error if presented with a comment containing file.

This is designed to mimick the structure of the Statsbook as closely
as possible - even though there may be better ways to organize the
data in a data structure, we do not attempt to do so.
 
