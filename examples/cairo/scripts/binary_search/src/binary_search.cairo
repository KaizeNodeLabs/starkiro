/// Binary search implementation with O(log n) complexity
/// Returns Some(index) if found, None if not found
/// Requires input array to be sorted in ascending order
/// # Arguments
/// * `span` - Sorted span to search in
/// * `val` - Target value to find

#[derive(Copy, Drop)]
struct State<T> {
    span: Span<T>,
    val: T,
    left: u32,
    right: u32
}

pub fn binary_search<T, +Copy<T>, +Drop<T>, +PartialEq<T>, +PartialOrd<T>>(
    span: Span<T>, 
    val: T
) -> Option<u32> {
    if span.len() == 0 {
        return Option::None;
    }

    let state = State { span, val, left: 0, right: span.len() - 1 };
    search(state)
}

pub fn search<T, +Copy<T>, +Drop<T>, +PartialEq<T>, +PartialOrd<T>>(
    mut state: State<T>
) -> Option<u32> {
    if state.left > state.right {
        return Option::None;
    }

    let mid = state.left + (state.right - state.left) / 2;
    let mid_val = *state.span[mid];

    if mid_val == state.val {
        Option::Some(mid)
    } else if mid_val > state.val {
        if mid == 0 {
            Option::None
        } else {
            state.right = mid - 1;
            search(state)
        }
    } else {
        state.left = mid + 1;
        search(state)
    }
}

fn main() {
    // Empty array test
    let empty_arr: Array<u128> = array![];
    println!("\nTesting with empty array:");
    match binary_search(empty_arr.span(), 10) {
        Option::Some(index) => println!("Value 10 found at index {}", index),
        Option::None => println!("Value 10 not found in empty array")
    }

    // Normal array test
    let arr: Array<u128> = array![10, 20, 30, 40, 50, 60, 70, 80, 90, 100];
    let span = arr.span();
    
    println!("\nTesting with populated array:");
    let test_values = array![10, 50, 100, 5, 95, 45];
    
    for value in test_values {
        match binary_search(span, value) {
            Option::Some(index) => println!("Value {} found at index {}", value, index),
            Option::None => println!("Value {} not found in array", value)
        }
    }
}
