// This version of the clear_scores function won't work with Cairo's current version.
// /// Clear the array passed as argument
// fn clear_scores(ref array: Array<i32>) {
//     // Loop through the array
//     while array.len() > 0 {
//         // Remove the first element of the array
//         array.pop_front().unwrap();
//     }
// }

// Temporary implementation for version prior to Cairo 2.9.3
fn clear_scores() -> Array<i32> {
    ArrayTrait::new()
}

/// Get the three highest values stored in the array passed as argument
fn get_top_three(ref array: Array<i32>) -> Array<i32> {
    // Create 3 variables to store the highest values
    let mut a = 0;
    let mut b = 0;
    let mut c = 0;

    // Loop through the array
    for i in 0..array.len() {
        let score = *array[i];

        // Check if the current element is greater than our stored values
        if score > a {
            c = b;
            b = a;
            a = score;
        } else if score > b {
            c = b;
            b = score;
        } else if score > c {
            c = score;
        }
    };

    array![a, b, c]
}

/// Get the latest value added to the array
fn get_last_score(ref array: Array<i32>) -> i32 {
    *array[array.len() - 1]
}

/// Get the highest value from the array passed as argument
fn get_highest(ref array: Array<i32>) -> i32 {
    let mut highest = 0;

    // Loop through the array
    for i in 0..array.len() {
        // Check if the current element is greater than the element stored
        if *array[i] > highest {
            // Update highest with the current element
            highest = *array[i];
        }
    };

    highest
}

/// Add a new value to the array passed as argument
fn add_score(score: i32, ref array: Array<i32>) {
    array.append(score);
}

fn main() {
    // Create a new array
    let mut scoreboard: Array<i32> = ArrayTrait::new();

    // Use the add_score() function to add numbers to our array
    println!("\n|-------------------[   add_score()    ]-------------------|");
    add_score(-83, ref scoreboard);
    add_score(-31, ref scoreboard);
    add_score(97, ref scoreboard);
    add_score(39, ref scoreboard);
    add_score(0, ref scoreboard);
    add_score(86, ref scoreboard);
    add_score(-29, ref scoreboard);
    add_score(67, ref scoreboard);
    add_score(-69, ref scoreboard);
    add_score(5, ref scoreboard);

    // Print out the array we just filled
    for i in 0..scoreboard.len() {
        println!(" Array[{}] = {}", i, scoreboard[i]);
    };

    // Print out the highest value found in the array using get_highest()
    println!("\n|-------------------[   get_highest()  ]-------------------|");
    println!(" Highest value in array = {}", get_highest(ref scoreboard));

    // Print out the last value added to the array using get_last_score()
    println!("\n|-------------------[ get_last_score() ]-------------------|");
    println!(" Last score added to array = {}", get_last_score(ref scoreboard));

    // Find the three highest scores in the array using get_top_three() and print them
    println!("\n|-------------------[ get_top_three()  ]-------------------|");
    let top_three = get_top_three(ref scoreboard);
    println!(" The three highest values in the array are: ");
    for i in 0..top_three.len() {
        println!("   {}", top_three[i]);
    };

    // CLear the array using clear_scores()
    println!("\n|-------------------[  clear_scores()  ]-------------------|");
    println!(" Array length before clearing it = {}", scoreboard.len());
    scoreboard = clear_scores();
    // ! Not working with Cairo's current version !
// println!(" Array length after clearing it = {}", scoreboard.len());
}
