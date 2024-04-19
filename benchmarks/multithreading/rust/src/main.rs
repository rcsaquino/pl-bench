use serde_json;
use std::sync::mpsc;
use std::thread;
use std::thread::available_parallelism;

fn main() {
    let possible_answers: Vec<String> = serde_json::from_str(include_str!(
        "benchmarks/multithreading/db_words/wordle_min.json"
    ))
    .unwrap();

    let mut priority_index = vec![0; possible_answers.len()];

    let thread_count = available_parallelism().unwrap().get();
    let chunk_size: usize = (possible_answers.len() as f64 / thread_count as f64).ceil() as usize;
    let possible_answers = possible_answers.clone();

    let rx_main = {
        let (tx, rx) = mpsc::channel();
        for chunk in 0..thread_count {
            let from = chunk_size * chunk;
            let to = {
                if (from + chunk_size) > possible_answers.len() {
                    possible_answers.len()
                } else {
                    from + chunk_size
                }
            };
            let possible_answers = possible_answers.clone();
            let tx = tx.clone();
            thread::spawn(move || {
                let mut priority_index = vec![0; possible_answers.len()];
                for x in from..to {
                    for y in 0..possible_answers.len() {
                        for a_char_index in 0..5 {
                            let a_char = possible_answers[x].chars().nth(a_char_index).unwrap();
                            if a_char == possible_answers[y].chars().nth(a_char_index).unwrap() {
                                priority_index[y] += 5;
                            } else if possible_answers[y].contains(a_char) {
                                priority_index[y] += 4;
                            }
                        }
                    }
                }

                tx.send(priority_index).unwrap();
            });
        }

        rx //return
    };

    for r in rx_main {
        for (i, prio) in r.iter().enumerate() {
            priority_index[i] += prio;
        }
    }

    let reference_index = priority_index.clone();

    priority_index.sort_by(|a, b| b.partial_cmp(a).unwrap());

    let mut result = String::from("Rust: ");
    for i in 0..5 {
        let score = priority_index[i];
        let index = reference_index
            .iter()
            .position(|&x| x == priority_index[i])
            .unwrap();
        result.push_str(format!("{}: {} | ", possible_answers[index], score).as_str());
    }

    println!("{}", result);
}
