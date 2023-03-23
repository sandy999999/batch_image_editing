#!/bin/zsh

# Define the desired sizes for each geometric group
large_horizontal_rectangle_standard="1600x1000"
large_vertical_rectangle_standard="1000x1600"
large_horizontal_rectangle_narrow="2000x1000"
large_vertical_rectangle_narrow="1000x2000"
large_quadratic="1000x1000"
large_rectangle_standard="1920x1080"
large_rectangle_narrow="2400x1000"

small_horizontal_rectangle_standard="800x500"
small_vertical_rectangle_standard="500x800"
small_horizontal_rectangle_narrow="1000x500"
small_vertical_rectangle_narrow="500x1000"
small_quadratic="500x500"

# Define a function to process images
process_image() {
  input_file=$1
  output_file=$2
  target_size=$3

  # Resize and crop the image while maintaining aspect ratio
  convert "$input_file" -resize "$target_size^" -gravity center -extent "$target_size" -quality 100 -format webp "$output_file"
}

# Iterate over all files in the current folder
for file in *; do
  # Check if the file is an image
  if [[ -f $file ]] && identify -quiet "$file" &>/dev/null; then
    # Get the image dimensions
    dimensions=$(identify -define png:ignore-icc -format '%w %h' $file)
    width=$(echo $dimensions | cut -d ' ' -f 1)
    height=$(echo $dimensions | cut -d ' ' -f 2)

    # Check if the image is too small
    if [[ $width -lt 500 || $height -lt 500 ]]; then
      output_file="too_small_$(basename $file)"
      output_file="${output_file%.*}.webp"
      cp "$file" "$output_file"
      continue
    fi

    aspect_ratio=$(identify -define png:ignore-icc -format '%[fx:w/h]' $file)

    # Update the aspect ratio conditions based on your requirements
    if (( $(echo "$aspect_ratio > 1.1 && $aspect_ratio <= 1.9" | bc -l) )); then
      # Horizontal rectangle
      if [[ $width -lt 1000 || $height -lt 1000 ]]; then
        prefix="small_horizontal_rectangle_standard"
        geometry=$small_horizontal_rectangle_standard
      else
        prefix="large_horizontal_rectangle_standard"
        geometry=$large_horizontal_rectangle_standard
      fi
    elif (( $(echo "$aspect_ratio >= 0.5 && $aspect_ratio <= 0.9" | bc -l) )); then
      # Vertical rectangle
      if [[ $width -lt 1000 || $height -lt 1000 ]]; then
        prefix="small_vertical_rectangle_standard"
        geometry=$small_vertical_rectangle_standard
      else
        prefix="large_vertical_rectangle_standard"
        geometry=$large_vertical_rectangle_standard
      fi
    else
      # Default case: Quadratic
      if [[ $width -lt 1000 || $height -lt 1000 ]]; then
        prefix="small_quadratic"
        geometry=$small_quadratic
      else
        prefix="large_quadratic"
        geometry=$large_quadratic
      fi
    fi

    # Set the output filename
    output_file="${prefix}_$(basename $file)"
    output_file="${output_file%.*}.webp"

    # Process the image
    process_image "$file" "$output_file" "$geometry"
  fi
done