#!/usr/bin/env python3
"""
AI-powered context classifier using lightweight ML to predict work type from history patterns.
Uses a simple feature-based approach without external ML dependencies (pure Python).
"""

import sys
import json
import re
import math
from collections import defaultdict, Counter
from typing import Dict, List, Tuple


class SimpleNaiveBayesClassifier:
    """Lightweight Naive Bayes classifier for work type prediction."""
    
    def __init__(self):
        self.class_counts = Counter()
        self.feature_counts = defaultdict(lambda: Counter())
        self.vocabulary = set()
        self.trained = False
    
    def extract_features(self, context: Dict) -> List[str]:
        """Extract meaningful features from context data."""
        features = []
        
        # Process name features
        process = context.get('process_name', '').lower()
        if process:
            features.append(f'proc:{process}')
        
        # Window title features (tokenized)
        window_title = context.get('window_title', '').lower()
        for token in re.findall(r'\w+', window_title):
            if len(token) > 2:  # Skip short tokens
                features.append(f'title:{token}')
        
        # Working directory features
        cwd = context.get('process_cwd', '')
        if cwd:
            if 'projects' in cwd:
                features.append('cwd:projects')
            if 'docs' in cwd:
                features.append('cwd:docs')
            if 'test' in cwd:
                features.append('cwd:test')
        
        # Command line features
        cmdline = context.get('process_cmdline', '').lower()
        for keyword in ['test', 'deploy', 'docker', 'ssh', 'npm', 'git', 'python', 'node']:
            if keyword in cmdline:
                features.append(f'cmd:{keyword}')
        
        # URL patterns (if present)
        if 'url' in context:
            url = context['url'].lower()
            if 'github' in url:
                features.append('url:github')
            if 'docs' in url or 'documentation' in url:
                features.append('url:docs')
            if 'mail' in url or 'inbox' in url:
                features.append('url:mail')
        
        return features
    
    def train(self, training_data: List[Tuple[Dict, str]]):
        """Train on historical context data with known labels."""
        for context, label in training_data:
            self.class_counts[label] += 1
            features = self.extract_features(context)
            for feature in features:
                self.vocabulary.add(feature)
                self.feature_counts[label][feature] += 1
        
        self.trained = True
    
    def predict(self, context: Dict) -> Tuple[str, float]:
        """Predict work type with confidence score."""
        if not self.trained or not self.class_counts:
            # Fallback to heuristic-based classification
            return self._heuristic_classify(context)
        
        features = self.extract_features(context)
        scores = {}
        total_docs = sum(self.class_counts.values())
        
        for work_class in self.class_counts:
            # Prior probability
            prior = self.class_counts[work_class] / total_docs
            log_prob = math.log(prior)
            
            # Likelihood with Laplace smoothing
            class_feature_count = sum(self.feature_counts[work_class].values())
            vocab_size = len(self.vocabulary)
            
            for feature in features:
                feature_count = self.feature_counts[work_class][feature]
                # Laplace smoothing
                prob = (feature_count + 1) / (class_feature_count + vocab_size)
                log_prob += math.log(prob)
            
            scores[work_class] = log_prob
        
        if not scores:
            return self._heuristic_classify(context)
        
        # Get prediction with highest score
        predicted_class = max(scores, key=scores.get)
        max_score = scores[predicted_class]
        
        # Convert log probabilities to confidence (0-1 scale)
        # Use softmax-like normalization
        exp_scores = {k: math.exp(v - max_score) for k, v in scores.items()}
        total_exp = sum(exp_scores.values())
        confidence = exp_scores[predicted_class] / total_exp
        
        return predicted_class, confidence
    
    def _heuristic_classify(self, context: Dict) -> Tuple[str, float]:
        """Fallback heuristic-based classification when no training data."""
        window_title = context.get('window_title', '').lower()
        process = context.get('process_name', '').lower()
        cwd = context.get('process_cwd', '').lower()
        cmdline = context.get('process_cmdline', '').lower()
        
        # Code review signals
        if 'pull' in window_title or '/pr/' in window_title or 'code review' in window_title:
            return 'code-review', 0.75
        
        # Development signals
        if any(x in process for x in ['code', 'vim', 'nvim', 'emacs']) and 'projects' in cwd:
            return 'development', 0.80
        
        # Testing signals
        if any(x in cmdline for x in ['test', 'jest', 'mocha', 'pytest']):
            return 'testing', 0.85
        
        # Deployment/ops signals
        if any(x in process for x in ['ssh', 'docker']) or any(x in cmdline for x in ['deploy', 'kubernetes']):
            return 'ops-deployment', 0.80
        
        # Documentation signals
        if 'docs' in window_title or 'readme' in window_title or 'docs' in cwd:
            return 'documentation', 0.70
        
        # Communication signals
        if any(x in process for x in ['thunderbird', 'mail', 'slack', 'discord']):
            return 'communication', 0.85
        
        # Research/browsing
        if any(x in process for x in ['firefox', 'chrome', 'chromium']):
            return 'research', 0.60
        
        return 'unknown', 0.30


def load_training_data(history_file: str) -> List[Tuple[Dict, str]]:
    """Load and parse historical session data for training."""
    training_data = []
    
    try:
        with open(history_file, 'r') as f:
            for line in f:
                try:
                    entry = json.loads(line.strip())
                    # Expect entries with context and label
                    if 'context' in entry and 'work_type' in entry:
                        training_data.append((entry['context'], entry['work_type']))
                except json.JSONDecodeError:
                    continue
    except FileNotFoundError:
        pass  # No training data available
    
    return training_data


def main():
    """Main entry point for context classifier."""
    # Parse input JSON from stdin
    try:
        input_data = json.load(sys.stdin)
    except json.JSONDecodeError as e:
        print(json.dumps({'error': f'Invalid JSON input: {e}'}), file=sys.stderr)
        sys.exit(1)
    
    # Initialize classifier
    classifier = SimpleNaiveBayesClassifier()
    
    # Attempt to load training data (optional)
    # Training data should be in ~/.work-context/training.jsonl
    import os
    training_file = os.path.expanduser('~/.work-context/training.jsonl')
    training_data = load_training_data(training_file)
    
    if training_data:
        classifier.train(training_data)
    
    # Predict work type
    predicted_type, confidence = classifier.predict(input_data)
    
    # Add AI predictions to output
    output = input_data.copy()
    output['ai_predicted_worktype'] = predicted_type
    output['ai_confidence'] = round(confidence, 3)
    output['ai_classifier_trained'] = classifier.trained
    output['ai_training_samples'] = len(training_data)
    
    print(json.dumps(output, indent=2))


if __name__ == '__main__':
    main()
