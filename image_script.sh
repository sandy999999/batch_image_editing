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

# Calculate absolute difference between two aspect ratios
calculate_difference() {
  echo "scale=6; abs($1 - $2)" | bc
}

# Get the best geometry for the given image
get_best_geometry() {
  original_aspect_ratio=$1
  candidate_geometries=$2
  min_difference=999999
  best_geometry=""

  for candidate_geometry in $candidate_geometries; do
    candidate_aspect_ratio=$(echo $candidate_geometry | awk -F 'x' '{ print $1/$2 }')
    difference=$(calculate_difference $original_aspect_ratio $candidate_aspect_ratio)
    if (( $(echo "$difference < $min_difference" | bc -l) )); then
      min_difference=$difference
      best_geometry=$candidate_geometry
    fi
  done

  echo $best_geometry
}

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
    prefix=""
    geometry_candidates=""

    if (( $(echo "$aspect_ratio >= 0.9 && $aspect_ratio <= 1.1" | bc -l) )); then
      prefix="square_"
      geometry_candidates="$small_quadratic_square $medium_quadratic_square $large_quadratic_square $x_large_quadratic_square $xx_large_quadratic_square"
    elif (( $(echo "$aspect_ratio > 1.1" | bc -l) )); then
      prefix="vertical_"
      if (( $(echo "$aspect_ratio >= 1.5" | bc -l) )); then
        geometry_candidates="$small_vertical_rectangle_narrow $medium_vertical_rectangle_narrow $large_vertical_rectangle_narrow $x_large_vertical_rectangle_narrow $xx_large_vertical_rectangle_narrow"
      else
        geometry_candidates="$small_vertical_rectangle_normal $medium_vertical_rectangle_normal $large_vertical_rectangle_normal $x_large_vertical_rectangle_normal $xx_large_vertical_rectangle_normal"
      fi
    else
      prefix="horizontal_"
      if (( $(echo "$aspect_ratio <= 0.67" | bc -l) )); then
        geometry_candidates="$small_horizontal_rectangle_narrow $medium_horizontal_rectangle_narrow $large_horizontal_rectangle_narrow $x_large_horizontal_rectangle_narrow $xx_large_horizontal_rectangle_narrow"
      else
        geometry_candidates="$small_horizontal_rectangle_normal $medium_horizontal_rectangle_normal $large_horizontal_rectangle_normal $x_large_horizontal_rectangle_normal $xx_large_horizontal_rectangle_normal"
      fi
    fi

    # Get the best geometry for the given image
    best_geometry=$(get_best_geometry $aspect_ratio "$geometry_candidates")

    # Process the image
    output_file="${prefix}$(basename $file)"
    output_file="${output_file%.*}.webp"
    process_image "$file" "$output_file" "$best_geometry"
  fi
done