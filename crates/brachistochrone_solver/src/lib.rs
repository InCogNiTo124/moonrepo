use std::f64::consts::{PI, TAU};
use wasm_bindgen::prelude::*;

const NUM_POINTS: i32 = 256;
const PRECISION: f64 = 1e-6;

#[wasm_bindgen]
#[allow(dead_code)]
extern "C" {
    // Use `js_namespace` here to bind `console.log(..)` instead of just
    // `log(..)`
    #[wasm_bindgen(js_namespace = console)]
    fn error(s: &str);
}

#[wasm_bindgen]
struct BrachistochroneSolver {
    points: Vec<(f64, f64)>,
    pub theta_max: f64,
    pub rho: f64,
}

fn f(theta: f64) -> f64 {
    // function to be optimized
    // the domain has been restriced to [-2pi, 2pi] with a tanh transformation
    let t = TAU * theta.tanh();
    (t - t.sin()) / (1.0 - t.cos())

    // (theta - theta.sin()) / (1.0 - theta.cos())
}

fn f_prime(theta: f64) -> f64 {
    // symbollic derivative of the function f
    // also transformed to the domain [-2pi, 2pi] with tanh
    // (-t * sin_t - 2.0 * cos_t + 2.0) / (1.0 - cos_t).powi(2)
    // (-t * sin_t - 2.0 * cos_t + 2.0) / (1.0 - cos_t).powi(2)
    (TAU * (1.0 - PI * theta.tanh() / (PI * theta.tanh()).tan()))
        / ((PI * theta.tanh()).sin().powi(2) * theta.cosh().powi(2))
}

fn initial_guess(x: f64) -> f64 {
    // best initial guess for theta of f(theta) = k
    // ideally this would be an inverse function
    // I'm approximating it with Pade
    // details at https://terra-incognita.blog/brachistochrone
    // TAU - horner(x, &num) / horner(x, &denom)
    (x / 3.0).atan()
}

fn newton_raphson(k: f64) -> f64 {
    // optimization of the function
    // f(theta) = (theta - sin(theta)) / (1 - cos(theta)) = k

    // TODO maybe bug
    // let mut theta = (initial_guess(k) / TAU).atanh();
    let mut theta = initial_guess(k);
    // log(std::format!("k: {}", k).as_str());
    // log(std::format!("initial guess: {}", theta).as_str());
    // log(std::format!("f(theta): {}", f(theta)).as_str());
    for _ in 0..100 {
        if (f(theta) - k).abs() < PRECISION {
            break;
        }
        theta = theta - (f(theta) - k) / f_prime(theta);
        // log(std::format!("better guess: {}", theta).as_str());
        // if theta > TAU {
        // theta = TAU - theta.rem_euclid(TAU);
        // continue;
        // }
        // if theta < -TAU {
        // theta = theta.rem_euclid(-TAU) + TAU;
        // continue;
        // }
        // let better_theta = (theta.cos() - 1.0) * (k * (theta.cos() - 1.0) + theta - theta.sin())
        // / (theta * theta.sin() + 2.0 * theta.cos() - 2.0);
    }
    theta.tanh() * TAU
}

#[wasm_bindgen]
#[allow(dead_code)] // Add this line to suppress dead code warnings for the impl block
impl BrachistochroneSolver {
    pub fn new() -> Self {
        BrachistochroneSolver {
            points: vec![],
            theta_max: 0.0,
            rho: 0.0,
        }
    }

    pub fn solve(&mut self, x0: f64, y0: f64, x1: f64, y1: f64) {
        // Translate coordinates such that the higer of (x0, y0) and (x1, y1) is the origin
        // here "higer" means in the human view, but y axis is inverted
        let (start_x, start_y, delta_x, delta_y) = if y0 < y1 {
            (x0, y0, x1 - x0, y1 - y0)
        } else {
            (x1, y1, x0 - x1, y0 - y1)
        };
        // log(std::format!("delta_x: {}, delta_y: {}", delta_x, delta_y).as_str());
        self.theta_max = newton_raphson(delta_x / delta_y);
        if !self.theta_max.is_finite() {
            error(format![
                "WASM solver encountered an error:\ndelta_x: {}\ndelta_y: {}\nk: {}\ntheta_opt: {}",
                delta_x,
                delta_y,
                delta_x / delta_y,
                self.theta_max
            ].as_str());
        }
        self.rho = delta_y / (1.0 - self.theta_max.cos());
        // log(std::format!("theta_opt: {}, rho: {}", theta_opt, rho).as_str());
        self.populate_points(start_x, start_y);
    }

    pub fn points(&self) -> *const (f64, f64) {
        self.points.as_ptr()
    }

    fn populate_points(&mut self, x0: f64, y0: f64) {
        // Populate points along the brachistochrone curve
        self.points.clear();
        self.points.push((x0, y0));
        for i in 1..=NUM_POINTS {
            let t = i as f64 / NUM_POINTS as f64;
            // TODO most likely a bug
            // let theta = theta_opt + t * (std::f64::consts::PI - theta_opt);
            let theta = self.theta_max * t;
            let x = x0 + self.rho * (theta - theta.sin());
            let y = y0 + self.rho * (1.0 - theta.cos());
            self.points.push((x, y));
        }
    }
}
