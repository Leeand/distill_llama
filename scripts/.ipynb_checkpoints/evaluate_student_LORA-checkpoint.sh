#!/bin/bash
export PYTHONPATH='.'

base_model=$1 # e.g., huggyllama/llama-7b
tune_ckpt_name=$2  # e.g., student_tune_log/llama_13000yahma_alpaca   tune_log/k1_h1_t1/globalstep_6500 tune_log/k1_h1_t4/globalstep_6500 tune_log/k1_h1_t8/globalstep_6500
prune_ckpt=$3 # e.g., prune_log/llama_prune

tune_id="${tune_ckpt_name##*/}"
python lm-evaluation-harness/main.py --model hf-causal-experimental --model_args  checkpoint=$prune_ckpt/pytorch_model.bin,peft=$tune_ckpt_name,config_pretrained=$base_model --tasks openbookqa,arc_easy,winogrande,hellaswag,arc_challenge,piqa,boolq --device cuda:0 --output_path results/${tune_id}.json --no_cache
# accelerate launch lm-evaluation-harness/main.py --model hf-causal-experimental --model_args checkpoint=$prune_ckpt/pytorch_model.bin,peft=$tune_ckpt_name,config_pretrained=$base_model --tasks openbookqa,arc_easy,winogrande,hellaswag,arc_challenge,piqa,boolq --device cuda:0,1,2,3 --output_path results/${tune_id}.json --no_cache

# accelerate launch '80GB' lm-evaluation-harness/main.py  --model hf-causal-experimental --model_args checkpoint=$prune_ckpt/pytorch_model.bin,peft=$tune_ckpt_name,config_pretrained=$base_model --tasks openbookqa,arc_easy,winogrande,hellaswag,arc_challenge,piqa,boolq --output_path results/${tune_id}.json --no_cache
