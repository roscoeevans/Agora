#!/bin/bash

# Skeleton Loading System Validation Script
# Validates complete skeleton loading flow, animation timing, accessibility compliance,
# and dependency architecture as specified in task 14.

set -e

echo "🧪 Starting Skeleton Loading System Validation..."
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Function to run a test and track results
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -e "${BLUE}Testing: $test_name${NC}"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if eval "$test_command" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASSED: $test_name${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}❌ FAILED: $test_name${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    echo ""
}

# Function to validate file exists
validate_file() {
    local file_path="$1"
    local description="$2"
    
    if [ -f "$file_path" ]; then
        echo -e "${GREEN}✅ Found: $description${NC}"
        return 0
    else
        echo -e "${RED}❌ Missing: $description${NC}"
        return 1
    fi
}

echo "1. Validating Skeleton System Architecture"
echo "----------------------------------------"

# Validate core skeleton components exist
validate_file "Packages/Kits/DesignSystem/Sources/DesignSystem/Skeleton/SkeletonTheme.swift" "SkeletonTheme protocol"
validate_file "Packages/Kits/DesignSystem/Sources/DesignSystem/Skeleton/FeedPostSkeletonView.swift" "FeedPostSkeletonView component"
validate_file "Packages/Kits/DesignSystem/Sources/DesignSystem/Skeleton/CommentSkeletonView.swift" "CommentSkeletonView component"
validate_file "Packages/Kits/DesignSystem/Sources/DesignSystem/Skeleton/ShimmerView.swift" "ShimmerView animation"
validate_file "Packages/Kits/DesignSystem/Sources/DesignSystem/Skeleton/SkeletonModifier.swift" "Skeleton modifier"

# Validate Feature integrations exist
validate_file "Packages/Features/HomeForYou/Sources/HomeForYou/FeedSkeletonIntegration.swift" "HomeForYou skeleton integration"
validate_file "Packages/Features/HomeFollowing/Sources/HomeFollowing/FeedSkeletonIntegration.swift" "HomeFollowing skeleton integration"
validate_file "Packages/Features/Profile/Sources/Profile/ProfileSkeletonIntegration.swift" "Profile skeleton integration"
validate_file "Packages/Features/PostDetail/Sources/PostDetail/CommentSheetSkeleton.swift" "CommentSheet skeleton integration"

echo ""
echo "2. Testing DesignSystem Skeleton Components"
echo "----------------------------------------"

# Test DesignSystem skeleton components
run_test "DesignSystem skeleton component creation" \
    "swift test --package-path Packages/Kits/DesignSystem --filter testCompleteSkeletonFlowRecommendedFeed"

run_test "Skeleton animation timing validation" \
    "swift test --package-path Packages/Kits/DesignSystem --filter testConsistent300msCrossfadeAnimationTiming"

run_test "Skeleton accessibility compliance" \
    "swift test --package-path Packages/Kits/DesignSystem --filter testVoiceOverAccessibilityCompliance"

run_test "Skeleton theme consistency" \
    "swift test --package-path Packages/Kits/DesignSystem --filter testSkeletonThemeConsistency"

run_test "Skeleton performance standards" \
    "swift test --package-path Packages/Kits/DesignSystem --filter testSkeletonPerformanceStandards"

echo ""
echo "3. Testing Feature Skeleton Integrations"
echo "---------------------------------------"

# Test HomeForYou skeleton integration
run_test "HomeForYou skeleton integration" \
    "swift test --package-path Packages/Features/HomeForYou --filter testHomeForYouSkeletonIntegration"

# Test HomeFollowing skeleton integration
run_test "HomeFollowing skeleton integration" \
    "swift test --package-path Packages/Features/HomeFollowing --filter testHomeFollowingSkeletonIntegration"

# Test Profile skeleton integration
run_test "Profile skeleton integration" \
    "swift test --package-path Packages/Features/Profile --filter testProfileSkeletonIntegration"

# Test PostDetail skeleton integration
run_test "PostDetail skeleton integration" \
    "swift test --package-path Packages/Features/PostDetail --filter testCommentSheetSkeletonIntegration"

echo ""
echo "4. Validating Cross-Surface Consistency"
echo "--------------------------------------"

run_test "Feed skeleton consistency between Recommended and Following" \
    "swift test --package-path Packages/Kits/DesignSystem --filter testSkeletonConsistencyBetweenRecommendedAndFollowing"

run_test "Profile skeleton consistency with main feeds" \
    "swift test --package-path Packages/Kits/DesignSystem --filter testSkeletonConsistencyBetweenFeedsAndProfile"

run_test "Comment skeleton compact layout validation" \
    "swift test --package-path Packages/Kits/DesignSystem --filter testCommentSkeletonCompactLayout"

echo ""
echo "5. Testing Dependency Architecture Compliance"
echo "--------------------------------------------"

run_test "DesignSystem dependency compliance" \
    "swift test --package-path Packages/Kits/DesignSystem --filter testDesignSystemDependencyCompliance"

run_test "Feature dependency isolation" \
    "swift test --package-path Packages/Kits/DesignSystem --filter testFeatureDependencyIsolation"

run_test "Analytics Kit optional integration" \
    "swift test --package-path Packages/Kits/DesignSystem --filter testAnalyticsKitOptionalIntegration"

echo ""
echo "6. Validating Requirements Compliance"
echo "-----------------------------------"

# Validate all requirements from the specification
run_test "Requirement 1: Immediate visual feedback (200ms target)" \
    "swift test --package-path Packages/Kits/DesignSystem --filter testRequirement1_ImmediateVisualFeedback"

run_test "Requirement 2: Consistent feed experience" \
    "swift test --package-path Packages/Kits/DesignSystem --filter testRequirement2_ConsistentFeedExperience"

run_test "Requirement 5: Accessibility support" \
    "swift test --package-path Packages/Kits/DesignSystem --filter testRequirement5_AccessibilitySupport"

run_test "Requirement 6: Performance standards" \
    "swift test --package-path Packages/Kits/DesignSystem --filter testRequirement6_PerformanceStandards"

run_test "Requirement 7: Reusable components" \
    "swift test --package-path Packages/Kits/DesignSystem --filter testRequirement7_ReusableComponents"

run_test "Requirement 8: Shared theming foundation" \
    "swift test --package-path Packages/Kits/DesignSystem --filter testRequirement8_SharedThemingFoundation"

echo ""
echo "7. Final Deployment Readiness Validation"
echo "---------------------------------------"

run_test "Complete skeleton system integration" \
    "swift test --package-path Packages/Kits/DesignSystem --filter testSkeletonSystemIntegration"

run_test "Deployment readiness validation" \
    "swift test --package-path Packages/Kits/DesignSystem --filter testDeploymentReadiness"

run_test "All requirements final validation" \
    "swift test --package-path Packages/Kits/DesignSystem --filter testAllRequirementsValidation"

echo ""
echo "8. Build Validation"
echo "------------------"

# Validate that the project builds successfully
echo -e "${BLUE}Testing: Project build validation${NC}"
TOTAL_TESTS=$((TOTAL_TESTS + 1))

if swift build > /dev/null 2>&1; then
    echo -e "${GREEN}✅ PASSED: Project builds successfully${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo -e "${RED}❌ FAILED: Project build failed${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi

echo ""
echo "=================================================="
echo "🧪 Skeleton Loading System Validation Complete"
echo "=================================================="
echo ""
echo "📊 Test Results Summary:"
echo "  Total Tests: $TOTAL_TESTS"
echo -e "  ${GREEN}Passed: $PASSED_TESTS${NC}"
echo -e "  ${RED}Failed: $FAILED_TESTS${NC}"
echo ""

# Calculate success percentage
if [ $TOTAL_TESTS -gt 0 ]; then
    SUCCESS_PERCENTAGE=$(( (PASSED_TESTS * 100) / TOTAL_TESTS ))
    echo "📈 Success Rate: $SUCCESS_PERCENTAGE%"
else
    SUCCESS_PERCENTAGE=0
fi

echo ""

# Final validation status
if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}🎉 ALL TESTS PASSED! Skeleton loading system is ready for deployment.${NC}"
    echo ""
    echo "✅ Complete skeleton loading flow validated across all feed surfaces"
    echo "✅ Consistent 300ms crossfade animation timing verified"
    echo "✅ Accessibility compliance with VoiceOver, Dynamic Type, and motion preferences validated"
    echo "✅ Dependency architecture compliance confirmed (no forbidden cross-Feature imports)"
    echo "✅ All requirements from task 14 successfully validated"
    echo ""
    exit 0
else
    echo -e "${RED}❌ VALIDATION FAILED! $FAILED_TESTS test(s) failed.${NC}"
    echo ""
    echo "Please review the failed tests above and fix any issues before deployment."
    echo ""
    exit 1
fi