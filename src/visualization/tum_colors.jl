import Plots.RGB
import Plots.palette, Plots.cgrad

const tum_colors = (
    # web 
    tum_blue_brand = RGB((48, 112, 179) ./ 255 ...),
    tum_blue_dark = RGB((7, 33, 64) ./ 255 ...),
    tum_blue_dark_1 = RGB((10, 45, 87) ./ 255 ...),
    tum_blue_dark_2 = RGB((14, 57, 110) ./ 255 ...),
    tum_blue_dark_3 = RGB((17, 69, 132) ./ 255 ...),
    tum_blue_dark_4 = RGB((20, 81, 154) ./ 255 ...),
    tum_blue_dark_5 = RGB((22, 93, 177) ./ 255 ...),
    tum_blue_light = RGB((94, 148, 212) ./ 255 ...),
    tum_blue_light_dark = RGB((154, 188, 228) ./ 255 ...),
    tum_blue_light_2 = RGB((194, 215, 239) ./ 255 ...),
    tum_blue_light_3 = RGB((215, 228, 244) ./ 255 ...),
    tum_blue_light_4 = RGB((227, 238, 250) ./ 255 ...),
    tum_blue_light_5 = RGB((240, 245, 250) ./ 255 ...),
    tum_yellow = RGB((254, 215, 2) ./ 255 ...),
    tum_yellow_dark = RGB((203, 171, 1) ./ 255 ...),
    tum_yellow_1 = RGB((254, 222, 52) ./ 255 ...),
    tum_yellow_2 = RGB((254, 230, 103) ./ 255 ...),
    tum_yellow_3 = RGB((254, 238, 154) ./ 255 ...),
    tum_yellow_4 = RGB((254, 246, 205) ./ 255 ...),
    tum_orange = RGB((247, 129, 30) ./ 255 ...),
    tum_orange_dark = RGB((217, 146, 8) ./ 255 ...),
    tum_orange_1 = RGB((249, 191, 78) ./ 255 ...),
    tum_orange_2 = RGB((250, 208, 128) ./ 255 ...),
    tum_orange_3 = RGB((252, 226, 176) ./ 255 ...),
    tum_orange_4 = RGB((254, 244, 225) ./ 255 ...),
    tum_pink = RGB((181, 92, 165) ./ 255 ...),
    tum_pink_dark = RGB((155, 70, 141) ./ 255 ...),
    tum_pink_1 = RGB((198, 128, 187) ./ 255 ...),
    tum_pink_2 = RGB((214, 164, 206) ./ 255 ...),
    tum_pink_3 = RGB((230, 199, 225) ./ 255 ...),
    tum_pink_4 = RGB((246, 234, 244) ./ 255 ...),
    tum_blue_bright = RGB((143, 129, 234) ./ 255 ...),
    tum_blue_bright_dark = RGB((105, 85, 226) ./ 255 ...),
    tum_blue_bright_1 = RGB((182, 172, 241) ./ 255 ...),
    tum_blue_bright_2 = RGB((201, 194, 245) ./ 255 ...),
    tum_blue_bright_3 = RGB((220, 216, 249) ./ 255 ...),
    tum_blue_bright_4 = RGB((239, 237, 252) ./ 255 ...),
    tum_red = RGB((234, 114, 55) ./ 255 ...),
    tum_red_dark = RGB((217, 81, 23) ./ 255 ...),
    tum_red_1 = RGB((239, 144, 103) ./ 255 ...),
    tum_red_2 = RGB((243, 178, 149) ./ 255 ...),
    tum_red_3 = RGB((246, 194, 172) ./ 255 ...),
    tum_red_4 = RGB((251, 234, 218) ./ 255 ...),
    tum_green = RGB((159, 186, 54) ./ 255 ...),
    tum_green_dark = RGB((125, 146, 42) ./ 255 ...),
    tum_green_1 = RGB((182, 206, 85) ./ 255 ...),
    tum_green_2 = RGB((199, 217, 125) ./ 255 ...),
    tum_green_3 = RGB((216, 229, 164) ./ 255 ...),
    tum_green_4 = RGB((233, 241, 203) ./ 255 ...),
    tum_grey_1 = RGB((32, 37, 42) ./ 255 ...),
    tum_grey_2 = RGB((51, 58, 65) ./ 255 ...),
    tum_grey_3 = RGB((71, 80, 88) ./ 255 ...),
    tum_grey_4 = RGB((106, 117, 126) ./ 255 ...),
    tum_grey_7 = RGB((221, 226, 230) ./ 255 ...),
    tum_grey_8 = RGB((235, 236, 239) ./ 255 ...),
    tum_grey_9 = RGB((251, 249, 250) ./ 255 ...),
    tum_white = RGB((255, 255, 255) ./ 255 ...),
)

const tum_colors_presentation = (
    # primary
    blue = RGB((0, 101, 189) ./ 255 ...),
    white = RGB((255, 255, 255) ./ 255 ...),
    black = RGB((0, 0, 0) ./ 255 ...),

    # secondary
    deepblue = RGB((0, 82, 147) ./ 255 ...),
    darkblue = RGB((0, 51, 89) ./ 255 ...),
    darkgrey = RGB((51, 51, 51) ./ 255 ...),
    grey = RGB((128, 128, 128) ./ 255 ...),
    lightgrey = RGB((204, 204, 204) ./ 255 ...),

    # tertiary
    sand = RGB((218, 215, 203) ./ 255 ...),
    orange = RGB((227, 114, 34) ./ 255 ...),
    green = RGB((162, 173, 0) ./ 255 ...),
    skyblue = RGB((152, 198, 234) ./ 255 ...),
    lightblue = RGB((100, 160, 200) ./ 255 ...),
)

const tum_colors_harmonic = palette([
    tum_colors.tum_blue_dark_2,     
    tum_colors.tum_blue_bright_dark, 
    tum_colors.tum_pink, 
    tum_colors.tum_red_dark, 
    tum_colors.tum_orange, 
    tum_colors.tum_yellow, 
    tum_colors.tum_green,
    tum_colors.tum_blue_light, 
])

const tum_colors_harmonic_grad = cgrad(tum_colors_harmonic)

const tum_colors_alternating = palette([
    tum_colors.tum_blue_dark_2,     
    tum_colors.tum_orange, 
    tum_colors.tum_blue_bright_dark, 
    tum_colors.tum_yellow, 
    tum_colors.tum_pink, 
    tum_colors.tum_green,
    tum_colors.tum_red_dark, 
    tum_colors.tum_blue_light, 
])

const tum_colors_alternating_grad = cgrad(tum_colors_alternating)