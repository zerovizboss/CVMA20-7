package com.cvma.promptapprover;

import java.util.List;

public class DecisionRequest {
    public long timestamp;
    public String context;
    public List<Option> options;
    public String rawPrompt;

    public static class Option {
        public int number;
        public String text;
    }
}