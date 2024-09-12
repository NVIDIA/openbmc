#!/usr/bin/awk -f

# Set the input field separator to space
BEGIN { FS = " " }

# Process each line of the input
{
  # Loop over each field and convert to binary
  for (i = 1; i <= NF; i++) {
    printf "%c", strtonum("0x" substr($i,3))
  }
}
