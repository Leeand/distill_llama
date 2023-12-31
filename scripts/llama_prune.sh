prune_ckpt_path='llama_prune'
tune_ckpt_path='llama_13000yahma_alpaca' 
hyperparamaters_name='k10_h0.5_t16_DDP' # update the name according the hyperparamaters

# echo "[START] - Start Pruning Model"
# CUDA_VISIBLE_DEVICES=0 python hf_prune.py --pruning_ratio 0.25 --device cpu  --eval_device cuda --block_wise --block_mlp_layer_start 4 --block_mlp_layer_end 30 --block_attention_layer_start 4 --block_attention_layer_end 30 --save_ckpt_log_name $prune_ckpt_path --pruner_type taylor --test_after_train --taylor param_first --save_model
# echo "[FINISH] - Finish Pruning Model"

# echo "[START] - Start Teacher LORA SFT"
# CUDA_VISIBLE_DEVICES=0 python teacher_LORA_post_training.py --data_path yahma/alpaca-cleaned --output_dir teacher_tune_log/$tune_ckpt_path --wandb_project llama_tune --lora_r 8 --num_epochs 2 --learning_rate 1e-4 --batch_size 128
# echo "[FINISH] - Finish Teacher Training."

# echo "[START] - Start Student Tuning"
# CUDA_VISIBLE_DEVICES=0 python student_post_training.py --prune_model prune_log/$prune_ckpt_path/pytorch_model.bin --data_path yahma/alpaca-cleaned --output_dir student_tune_log/$tune_ckpt_path --wandb_project student_llama_tune --lora_r 8 --num_epochs 2 --learning_rate 1e-4 --batch_size 64
# echo "[FINISH] - Finish Prune and Post-Training."
# echo "[INFO] - The prune d model is at {prune_log/$prune_ckpt_path/pytorch_model.bin}, and the Student LORA weight is at {student_tune_log/$tune_ckpt_path}/"
echo "[START] - Start Student Distill"
CUDA_VISIBLE_DEVICES=0 python -m torch.distributed.launch --nproc_per_node 1 distill_training.py --teacher_model_config teacher_tune_log/$tune_ckpt_path/ --student_tune_model_config student_tune_log/$tune_ckpt_path --prune_model prune_log/$prune_ckpt_path/pytorch_model.bin --data_path yahma/alpaca-cleaned --output_dir tune_log/$hyperparamaters_name --wandb_project my-awesome-project --lora_r 8 --num_epochs 2 --learning_rate 1e-4 --batch_size 3 --kd_loss_weight 10 --hard_label_weight 0.5 --temperature 16 --kd_type dynamic_temperature
# CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7 python distill_training.py --teacher_model_config teacher_tune_log/$tune_ckpt_path/ --global_step_start 1625  --student_tune_model_config  tune_log/$hyperparamaters_name/globalstep_1625 --prune_model prune_log/$prune_ckpt_path/pytorch_model.bin --data_path yahma/alpaca-cleaned --output_dir tune_log/$hyperparamaters_name --wandb_project my-awesome-project --lora_r 8 --num_epochs 1 --learning_rate 1e-4 --batch_size 4 --kd_loss_weight 1 --hard_label_weight 0.5 --temperature 8

echo "[FINISH] - Finish Prune and Post-Training."
echo "[INFO] - The pruned model is at {prune_log/$prune_ckpt_path/pytorch_model.bin}, and the recovery weight is at {tune_log/$tune_ckpt_path}/"

echo "You can use the command:"
echo "       python generate.py --model_type tune_prune_LLM --ckpt prune_log/$prune_ckpt_path/pytorch_model.bin --lora_ckpt tune_log/$tune_ckpt_path"
echo "to use the pruned model"

# student_tune_log/$tune_ckpt_path
# tune_log/$hyperparamaters_name/globalstep_3250 --global_step_start 3250

