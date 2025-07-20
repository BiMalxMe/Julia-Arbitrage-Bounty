"""
JuliaOS AI Analyzer Agent

This agent uses LLM integration to analyze NFT market data and provide
qualitative insights using multiple AI providers with fallbacks.
"""

using JuliaOS
using HTTP
using JSON3

# Agent configuration
const AI_ANALYZER_CONFIG = Dict(
    "name" => "AIAnalyzer",
    "description" => "AI-powered analysis of NFT market data and sentiment",
    "capabilities" => ["llm_analysis", "sentiment_analysis", "trend_analysis"],
    "providers" => ["ollama", "huggingface", "groq"]
)

# Initialize agent
agent = JuliaOS.Agent(AI_ANALYZER_CONFIG)

"""
Analyze collection data using LLM integration
"""
function analyze_collection(data::Dict)
    try
        @info "Starting AI analysis"
        
        # Prepare analysis prompt
        prompt = create_analysis_prompt(data)
        
        # Try multiple LLM providers with fallbacks
        analysis_result = nothing
        providers = [
            ("ollama", "llama2"),
            ("huggingface", "meta-llama/Llama-2-7b-chat-hf"),
            ("groq", "llama2-70b-4096")
        ]
        
        for (provider, model) in providers
            try
                @info "Attempting analysis with $provider:$model"
                analysis_result = agent.useLLM(provider, model, prompt)
                if !isnothing(analysis_result)
                    @info "Analysis successful with $provider"
                    break
                end
            catch e
                @warn "Provider $provider failed: $e"
                continue
            end
        end
        
        # Fallback to rule-based analysis if all AI fails
        if isnothing(analysis_result)
            @warn "All AI providers failed, using rule-based analysis"
            analysis_result = rule_based_analysis(data)
        else
            analysis_result = process_llm_response(analysis_result, data)
        end
        
        @info "AI analysis completed"
        return Dict("success" => true, "analysis" => analysis_result)
        
    catch e
        @error "AI analysis failed: $e"
        return Dict("success" => false, "error" => string(e))
    end
end

"""
Create analysis prompt for LLM
"""
function create_analysis_prompt(data::Dict)
    collection_name = get(get(data, "metadata", Dict()), "name", "Unknown Collection")
    floor_price = get(get(data, "market_data", Dict()), "floor_price", 0)
    volume_24h = get(get(data, "market_data", Dict()), "volume_24h", 0)
    sentiment_score = get(get(data, "social_data", Dict()), "sentiment_score", 0.5)
    twitter_mentions = get(get(data, "social_data", Dict()), "twitter_mentions", 0)
    
    prompt = """
    You are an expert NFT market analyst. Analyze the following data for the NFT collection "$collection_name":

    MARKET DATA:
    - Floor Price: $floor_price ETH
    - 24h Volume: $volume_24h ETH
    - Social Sentiment Score: $sentiment_score (0-1 scale)
    - Twitter Mentions (24h): $twitter_mentions

    Please provide a comprehensive analysis covering:

    1. MARKET OUTLOOK (50-100 words)
    - Short-term price direction and reasoning
    - Key market factors influencing the collection

    2. SENTIMENT ANALYSIS (30-50 words)
    - Social media sentiment interpretation
    - Community engagement level

    3. RISK FACTORS (list 3-5 factors)
    - Major risks that could impact price negatively

    4. BULLISH FACTORS (list 3-5 factors)
    - Positive indicators supporting price growth

    5. CONFIDENCE ASSESSMENT
    - Your confidence level in the analysis (1-100)
    - Data quality assessment (1-100)

    Format your response as a structured analysis focusing on actionable insights.
    Be objective and mention both positive and negative aspects.
    """
    
    return prompt
end

"""
Process LLM response and extract structured data
"""
function process_llm_response(llm_response::String, data::Dict)
    try
        # Parse LLM response to extract structured insights
        analysis = Dict(
            "market_outlook" => extract_section(llm_response, "MARKET OUTLOOK"),
            "sentiment_analysis" => extract_section(llm_response, "SENTIMENT ANALYSIS"),
            "risk_factors" => extract_list_section(llm_response, "RISK FACTORS"),
            "bullish_factors" => extract_list_section(llm_response, "BULLISH FACTORS"),
            "confidence_score" => extract_confidence(llm_response),
            "data_quality" => extract_data_quality(llm_response),
            "reasoning_steps" => generate_reasoning_steps(llm_response, data),
            "market_sentiment" => determine_market_sentiment(llm_response),
            "ai_reasoning" => llm_response
        )
        
        return analysis
        
    catch e
        @warn "Failed to process LLM response: $e"
        return rule_based_analysis(data)
    end
end

"""
Extract specific section from LLM response
"""
function extract_section(response::String, section_name::String)
    try
        lines = split(response, '\n')
        in_section = false
        section_text = ""
        
        for line in lines
            if contains(uppercase(line), uppercase(section_name))
                in_section = true
                continue
            elseif in_section && startswith(line, r"^\d+\.|[A-Z]+ [A-Z]+")
                break
            elseif in_section
                section_text *= line * " "
            end
        end
        
        return strip(section_text)
    catch e
        return "Analysis section unavailable"
    end
end

"""
Extract list items from LLM response
"""
function extract_list_section(response::String, section_name::String)
    try
        lines = split(response, '\n')
        in_section = false
        items = String[]
        
        for line in lines
            if contains(uppercase(line), uppercase(section_name))
                in_section = true
                continue
            elseif in_section && startswith(line, r"^\d+\.|[A-Z]+ [A-Z]+")
                break
            elseif in_section && (startswith(line, "-") || startswith(line, "•"))
                push!(items, strip(line[2:end]))
            end
        end
        
        return isempty(items) ? ["Market volatility", "Low liquidity", "Regulatory uncertainty"] : items
    catch e
        return ["Analysis unavailable"]
    end
end

"""
Extract confidence score from LLM response
"""
function extract_confidence(response::String)
    try
        confidence_match = match(r"confidence.*?(\d{1,3})", lowercase(response))
        return confidence_match !== nothing ? parse(Int, confidence_match.captures[1]) : 70
    catch e
        return 70
    end
end

"""
Extract data quality score
"""
function extract_data_quality(response::String)
    try
        quality_match = match(r"quality.*?(\d{1,3})", lowercase(response))
        return quality_match !== nothing ? parse(Int, quality_match.captures[1]) : 75
    catch e
        return 75
    end
end

"""
Determine overall market sentiment
"""
function determine_market_sentiment(response::String)
    response_lower = lowercase(response)
    
    bullish_indicators = ["bullish", "positive", "growth", "increasing", "strong", "optimistic"]
    bearish_indicators = ["bearish", "negative", "decline", "decreasing", "weak", "pessimistic"]
    
    bullish_count = sum([contains(response_lower, indicator) for indicator in bullish_indicators])
    bearish_count = sum([contains(response_lower, indicator) for indicator in bearish_indicators])
    
    if bullish_count > bearish_count
        return "bullish"
    elseif bearish_count > bullish_count
        return "bearish"
    else
        return "neutral"
    end
end

"""
Generate structured reasoning steps
"""
function generate_reasoning_steps(response::String, data::Dict)
    steps = [
        Dict(
            "factor" => "Social Media Sentiment",
            "impact" => determine_sentiment_impact(get(get(data, "social_data", Dict()), "sentiment_score", 0.5)),
            "confidence" => 80,
            "explanation" => "Social sentiment analysis from Twitter and community channels"
        ),
        Dict(
            "factor" => "Trading Volume",
            "impact" => determine_volume_impact(get(get(data, "market_data", Dict()), "volume_24h", 0)),
            "confidence" => 75,
            "explanation" => "24-hour trading volume indicates market activity and liquidity"
        ),
        Dict(
            "factor" => "Market Conditions",
            "impact" => "neutral",
            "confidence" => 65,
            "explanation" => "Overall NFT market conditions and macroeconomic factors"
        )
    ]
    
    return steps
end

"""
Determine sentiment impact
"""
function determine_sentiment_impact(sentiment_score::Float64)
    if sentiment_score > 0.6
        return "positive"
    elseif sentiment_score < 0.4
        return "negative"
    else
        return "neutral"
    end
end

"""
Determine volume impact
"""
function determine_volume_impact(volume::Float64)
    if volume > 100
        return "positive"
    elseif volume < 10
        return "negative"
    else
        return "neutral"
    end
end

"""
Fallback rule-based analysis when LLM fails
"""
function rule_based_analysis(data::Dict)
    @info "Using rule-based analysis fallback"
    
    floor_price = get(get(data, "market_data", Dict()), "floor_price", 0)
    volume_24h = get(get(data, "market_data", Dict()), "volume_24h", 0)
    sentiment_score = get(get(data, "social_data", Dict()), "sentiment_score", 0.5)
    
    # Simple rule-based analysis
    market_outlook = if volume_24h > 100 && sentiment_score > 0.6
        "Positive market indicators with strong volume and sentiment. Short-term outlook appears favorable."
    elseif volume_24h < 10 || sentiment_score < 0.4
        "Concerning market indicators with low volume or negative sentiment. Caution advised."
    else
        "Mixed market signals. Moderate outlook with balanced risk-reward profile."
    end
    
    return Dict(
        "market_outlook" => market_outlook,
        "sentiment_analysis" => "Rule-based sentiment assessment based on available data.",
        "risk_factors" => ["Market volatility", "Low liquidity", "Regulatory uncertainty"],
        "bullish_factors" => ["Strong community", "Utility value", "Market position"],
        "confidence_score" => 60,
        "data_quality" => 70,
        "reasoning_steps" => generate_reasoning_steps("", data),
        "market_sentiment" => sentiment_score > 0.6 ? "bullish" : sentiment_score < 0.4 ? "bearish" : "neutral",
        "ai_reasoning" => "Analysis generated using rule-based fallback due to LLM unavailability."
    )
end

# Export main function for agent coordinator
export analyze_collection