#!/bin/zsh

# Define the desired sizes for each geometric group
small_vertical_rectangle_normal="500x800"
medium_vertical_rectangle_normal="800x1280"
large_vertical_rectangle_normal="1000x1600"
x_large_vertical_rectangle_normal="1200x1920"
xx_large_vertical_rectangle_normal="1400x2240"

small_horizontal_rectangle_normal="800x500"
medium_horizontal_rectangle_normal="1280x800"
large_horizontal_rectangle_normal="1600x1000"
x_large_horizontal_rectangle_normal="1920x1200"
xx_large_horizontal_rectangle_normal="2240x1400"

small_vertical_rectangle_narrow="500x1000"
medium_vertical_rectangle_narrow="800x1600"
large_vertical_rectangle_narrow="1000x2000"
x_large_vertical_rectangle_narrow="1200x2400"
xx_large_vertical_rectangle_narrow="1400x2800"

small_horizontal_rectangle_narrow="1000x500"
medium_horizontal_rectangle_narrow="1600x800"
large_horizontal_rectangle_narrow="2000x1000"
x_large_horizontal_rectangle_narrow="2400x1200"
xx_large_horizontal_rectangle_narrow="2800x1400"

small_quadratic_square="500x500"
medium_quadratic_square="800x800"
large_quadratic_square="1000x1000"
x_large_quadratic_square="1200x1200"
xx_large_quadratic_square="1400x1400"

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

    # Set prefix and geometry based on aspect_ratio and size
    if (( $(echo "$aspect_ratio > 1.1 && $aspect_ratio <= 1.9" | bc -l) )); then
      # Horizontal rectangle (normal)
      if [[ $width -lt 1000 && $height -lt 1000 ]]; then
        prefix="small_horizontal_rectangle_normal"
        geometry=$small_horizontal_rectangle_normal
      elif [[ $width -lt 1600 && $height -lt 1600 ]]; then
        prefix="medium_horizontal_rectangle_normal"
        geometry=$medium_horizontal_rectangle_normal
      elif [[ $width -lt 1920 && $height -lt 1920 ]]; then
        prefix="large_horizontal_rectangle_normal"
        geometry=$large_horizontal_rectangle_normal
      elif [[ $width -lt 2240 && $height -lt 2240 ]]; then
        prefix="x_large_horizontal_rectangle_normal"
        geometry=$x_large_horizontal_rectangle_normal
      else
        prefix="xx_large_horizontal_rectangle_normal"
        geometry=$xx_large_horizontal_rectangle_normal
      fi
    elif (( $(echo "$aspect_ratio > 0.9 && $aspect_ratio <= 1.1" | bc -l) )); then
      # Quadratic square
      if [[ $width -lt 800 ]]; then
        prefix="small_quadratic_square"
        geometry=$small_quadratic_square
      elif [[ $width -lt 1000 ]]; then
        prefix="medium_quadratic_square"
        geometry=$medium_quadratic_square
      elif [[ $width -lt 1200 ]]; then
        prefix="large_quadratic_square"
        geometry=$large_quadratic_square
      elif [[ $width -lt 1400 ]]; then
        prefix="x_large_quadratic_square"
        geometry=$x_large_quadratic_square
      else
        prefix="xx_large_quadratic_square"
        geometry=$xx_large_quadratic_square
      fi
    else
      # Vertical rectangle (narrow or normal)
      if (( $(echo "$aspect_ratio <= 0.9" | bc -l) )); then
        prefix="vertical_rectangle_narrow"
      else
        prefix="vertical_rectangle_normal"
      fi
      if [[ $height -lt 1000 ]]; then
        prefix="small_$prefix"
        geometry=$small_vertical_rectangle_narrow
      elif [[ $height -lt 1600 ]]; then
        prefix="medium_$prefix"
        geometry=$medium_vertical_rectangle_narrow
      elif [[ $height -lt 1920 ]]; then
        prefix="large_$prefix"
        geometry=$large_vertical_rectangle_narrow
      elif [[ $height -lt 2240 ]]; then
        prefix="x_large_$prefix"
        geometry=$x_large_vertical_rectangle_narrow
      else
        prefix="xx_large_$prefix"
        geometry=$xx_large_vertical_rectangle_narrow
      fi
    fi

    # Process the image with the determined prefix and geometry
    output_file="${prefix}_$(basename $file)"
    output_file="${output_file%.*}.webp"
    process_image "$file" "$output_file" "$geometry"
  fi
done