#!/bin/bash
# Enable nullglob so that if no files match, the files array is empty
shopt -s nullglob

# Name of the combined header file
OUTPUT_HEADER="camera_index.h"

# Start the header file with an optional include guard.
echo "/* Combined header file for all index*.html files */" > "$OUTPUT_HEADER"
echo "#ifndef CAMERA_INDEX_H" >> "$OUTPUT_HEADER"
echo "#define CAMERA_INDEX_H" >> "$OUTPUT_HEADER"
echo "" >> "$OUTPUT_HEADER"

files=(index*.html)
if [ ${#files[@]} -eq 0 ]; then
  echo "No index*.html files found!"
  exit 1
fi

for file in "${files[@]}"; do
  echo "Processing $file..."

  # Gzip the HTML file (keeping the original intact)
  gzip -c "$file" > "${file}.gz"

  # Convert the gzipped file into a temporary C header snippet
  xxd -i "${file}.gz" > tmp_header.h

  # Extract the base name (e.g., index_ov2640 from index_ov2640.html)
  base="${file%.*}"
  # Get everything after "index" (for index.html, suffix will be empty)
  suffix="${base#index}"
  
  # Construct the variable name:
  # For "index.html" -> "index_html_gz"
  # For "index_ov2640.html" -> "index_ov2640_html_gz"
  if [ -n "$suffix" ]; then
    varname="index${suffix}_html_gz"
  else
    varname="index_html_gz"
  fi

  # The xxd output is similar to:
  #   unsigned char index_html_gz[] = { ... };
  #   unsigned int index_html_gz_len = <number>;
  #
  # Use sed to:
  # 1. Replace the array declaration with a const declaration using our variable name.
  sed -i.bak "s/unsigned char index_html_gz/const unsigned char ${varname}/g" tmp_header.h
  # 2. Replace the length declaration with a #define using our variable name.
  sed -i.bak "s/unsigned int index_html_gz_len/#define ${varname}_len/g" tmp_header.h
  # 3. Remove the '=' and trailing ';' so that the length becomes a proper macro.
  sed -i.bak "s/#define ${varname}_len = \([0-9]\+\);/#define ${varname}_len \1/" tmp_header.h
  rm -f tmp_header.h.bak

  # Append a comment header and then the modified data to the combined header file.
  {
    echo "/* Data for ${file} */"
    cat tmp_header.h
    echo ""
  } >> "$OUTPUT_HEADER"

  # Clean up temporary files.
  rm -f tmp_header.h "${file}.gz"
done

# Close the include guard.
echo "#endif // CAMERA_INDEX_H" >> "$OUTPUT_HEADER"

echo "Combined header file created: $OUTPUT_HEADER"

mv "$OUTPUT_HEADER" ../src/