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

    let rx = {
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
        rx
    };

    for r in rx {
        for (i, prio) in r.iter().enumerate() {
            priority_index[i] += prio;
        }
    }

    let mut word_hash_vec = possible_answers
        .clone()
        .into_iter()
        .zip(priority_index.into_iter())
        .collect::<Vec<(String, u32)>>();

    word_hash_vec.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap());

    println!(
        "Rust: {:?}",
        &word_hash_vec[if possible_answers.len() >= 5 {
            0..5
        } else {
            0..possible_answers.len()
        }]
    );
}
