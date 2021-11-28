#include "division.h"

const char *const DIVISION_BY_ZERO_MESSAGE = "Division by zero is illegal";

DivisionResult Division::divide() {
  if (fraction.denominator == 0L) throw DivisionByZero();

  DivisionResult result =
      DivisionResult{fraction.numerator / fraction.denominator,
                     fraction.numerator % fraction.denominator};

  return result;
}
