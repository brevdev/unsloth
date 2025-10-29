#!/usr/bin/env python3
"""
CUDA Initialization Fix for Unsloth in Docker

This script forces PyTorch CUDA initialization which is needed
in some Docker environments where lazy initialization fails.
"""

import os
import sys

def force_cuda_init():
    """Force CUDA initialization for PyTorch in Docker environments."""
    
    # Let Docker/NVIDIA runtime handle GPU visibility - don't override
    
    try:
        import torch
        
        # Force CUDA initialization
        torch.cuda.init()
        
        if torch.cuda.is_available():
            device_name = torch.cuda.get_device_name(0)
            device_count = torch.cuda.device_count()
            
            print(f"✅ CUDA initialized successfully!")
            print(f"   GPU: {device_name}")
            print(f"   Count: {device_count}")
            
            # Pre-warm CUDA to ensure it stays initialized
            _ = torch.zeros(1).cuda()
            
            # Now Unsloth should work
            try:
                from unsloth import FastLanguageModel
                print("✅ Unsloth imported successfully!")
                return True
            except Exception as e:
                print(f"⚠️ Unsloth import error: {e}")
                return False
        else:
            print("❌ CUDA not available after initialization")
            return False
            
    except Exception as e:
        print(f"❌ Error during CUDA initialization: {e}")
        return False

if __name__ == "__main__":
    success = force_cuda_init()
    sys.exit(0 if success else 1)

