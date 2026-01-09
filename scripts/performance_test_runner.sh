#!/bin/bash

echo "🚀 Running Performance Tests"

# Run unit tests
echo "📊 Running Unit Tests..."
flutter test test/unit/

# Run integration tests
echo "🔗 Running Integration Tests..."
flutter test integration_test/

# Run performance tests
echo "⚡ Running Load Tests..."
flutter test test/performance/

# Generate coverage report
echo "📈 Generating Coverage Report..."
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

echo "✅ Performance Tests Complete!"
