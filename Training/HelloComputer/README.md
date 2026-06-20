# Hello Computer NN Training

This folder holds offline training data for the tiny FAQ reranker in
`HelloComputerEngine.swift`.

The app should ship fixed weights. Do not train from live user traffic on-device.
Instead, add curated examples here, run the trainer locally, review metrics, then
manually copy approved weights into `HelloComputerFAQNeuralNetwork`.

## Data Shape

`hello_computer_training_data.json` has two stages:

- `supervised_examples`: labeled candidate examples where `label` is `1` for a
  correct candidate and `0` for a wrong candidate.
- `supervised_eval_examples`: held-out labeled examples that are never used for
  training, only for reporting.
- `preference_examples`: reinforcement-style feedback where a chosen candidate
  should be rewarded over a rejected candidate.
- `preference_eval_examples`: held-out preference pairs used to spot overfitting
  in the RL stage.

The RL stage is implemented as offline pairwise preference optimization. This is
closer to a contextual bandit/reranker than open-ended online RL, which keeps the
assistant deterministic and App Store safe.

## Run

```sh
python3 scripts/train_hello_computer_nn.py
```

The script prints train/eval metrics for both stages, optional overfit warnings,
and Swift-ready weights.

## Feature Order

Keep this order in sync with `faqFeatures(for:against:)`:

1. tag overlap
2. question overlap
3. phrase bonus
4. semantic similarity
5. matched tag phrases
6. contains question phrase
7. official FAQ source
8. query length
