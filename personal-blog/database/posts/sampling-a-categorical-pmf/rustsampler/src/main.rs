use core::f64;
use rand::prelude::*;
use rand_distr::Gumbel;
use serde::Serialize;
use std::fs::File;
use std::hint::black_box;
use std::io::{stdout, Write};
use std::time::Instant;
use tqdm::tqdm;

#[derive(Serialize)]
struct Data {
    method: String,
    x: Vec<u32>,
    y: Vec<f64>,
}

fn sample_linear(logits: &mut [f64], rng: &mut ThreadRng) -> usize {
    logits.iter_mut().for_each(|x| *x = x.exp());
    let sum = logits.iter().sum::<f64>();
    logits.iter_mut().for_each(|x| *x /= sum);
    logits.iter_mut().fold(0.0, |acc, x| {
        *x += acc;
        *x
    });
    let sample = rng.gen::<_>();
    let mut i = 0;
    for x in logits.iter() {
        if *x > sample {
            break;
        }
        i += 1;
    }
    i
}

fn sample_lg2(logits: &mut [f64], rng: &mut ThreadRng) -> usize {
    logits.iter_mut().for_each(|x| *x = x.exp());
    let sum = logits.iter().sum::<f64>();
    logits.iter_mut().for_each(|x| *x /= sum);
    logits.iter_mut().fold(0.0, |acc, x| {
        *x += acc;
        *x
    });
    let sample = rng.gen::<_>();
    let mut left = 0;
    let mut right = logits.len() - 1;

    while left < right {
        let mid = left + (right - left) / 2;
        if logits[mid] <= sample {
            left = mid + 1;
        } else {
            right = mid;
        }
    }
    left
}

fn sample_gumbel(logits: &mut [f64], rng: &mut ThreadRng) -> usize {
    let gumbel = Gumbel::new(0.0, 1.0).unwrap();
    logits
        .iter()
        .enumerate()
        .map(|(i, x)| (i, x + gumbel.sample(rng)))
        .max_by(|&a, &b| a.1.total_cmp(&b.1))
        .map(|(idx, _val)| idx)
        .unwrap()
}

fn sample_gumbel_direct(logits: &mut [f64], rng: &mut ThreadRng) -> usize {
    fn inner(xx: f64) -> f64 {
        let delta = f64::consts::E.recip();
        let q4 = -7.0 * f64::consts::E.powf(4.0) / 180.0;
        let q3 = f64::consts::E.powf(3.0) / 24.0;
        let q2 = -(f64::consts::E.powf(2.0)) / 6.0;

        let x = xx - delta;
        let numerator = f64::consts::E * x;
        let denominator = ((((q4 * x) + q3) * x + q2) * x) * x + 1.0;
        numerator / denominator
    }

    logits
        .iter()
        .enumerate()
        .map(|(i, x)| (i, x + inner(rng.gen())))
        .max_by(|&a, &b| a.1.total_cmp(&b.1))
        .map(|(idx, _val)| idx)
        .unwrap()
}

fn main() {
    let mut rng = rand::thread_rng();
    let mut data = Data {
        method: "gumbel_direct".to_string(),
        x: Vec::new(),
        y: Vec::new(),
    };
    let n_values = (100..1000)
        .step_by(100)
        .chain((1000..10000).step_by(1000))
        .chain((10000..=100000).step_by(10000));
    for n in tqdm(n_values) {
        let mut sum = 0;
        for _ in 0..10000 {
            let mut logits = (0..n).map(|_| rng.gen()).collect::<Vec<f64>>();
            let before = Instant::now();
            let _sample = sample_gumbel_direct(&mut logits, &mut rng);
            let duration = before.elapsed();
            sum += duration.as_micros();
        }
        let avg = (sum as f64) / 10000.0;
        data.x.push(n);
        data.y.push(avg);
    }

    println!["{}", serde_json::to_string(&data).unwrap()];
}
