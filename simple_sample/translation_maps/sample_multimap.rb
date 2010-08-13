# A multimap is an array of duples with some metadata. The first item in each duple is an
# object to be checked against the passed-in value using Ruby's '===' operator. 
#
# The first item of every single duple is checked against the passed in value, and
# we then collect *all* corresponding sencond-duple-values
#
# The most obvious use for this is to use pattern literals (e.g., /^University of/) as the "keys".
# Anything that makes sense for TheKey === PassedInValue is fine, though, including the slightly degenerate
# String === String
#

# In this example:
#
#   "Grad" => "Graduate Library" # rule 1
#             "A string Match"   # rule 4
#
#   "Grad Sci" => "Graduate Library", # rule 1
#                 "Science Library"  # rule 2
#
#   "Grad fict" => "Graduate Library", # rule 1
#                  "Fiction",          # rule 3
#                  "4th Floor"         # also rule 3



{
  :mapname => 'SimpleMultiMap',
  :maptype => :multi,
  :map => [
    [/^GRAD/i, "Graduate Library"],
    [/^GRAD SCI/i, "Science Library"],
    [/^GRAD FICT/i, ["Fiction", "4th Floor"]], # Note: multiple values are OK!
    ["Grad", "A String Match"]
   ]
  
}