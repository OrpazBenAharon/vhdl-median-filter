library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package filter_pkg is
  -- Define a constant for pixel width
  constant PIXEL_WIDTH : integer := 5;

  -- Subtype definitions
  subtype pixel_type is unsigned(PIXEL_WIDTH - 1 downto 0);
  subtype triple_sort_result is unsigned((3 * PIXEL_WIDTH) - 1 downto 0);

  -- Function Prototypes
  function triple_sort(
    p1, p2, p3 : pixel_type
  ) return triple_sort_result;

  function find_min3(
    p1, p2, p3 : pixel_type
  ) return pixel_type;

  function find_max3(
    p1, p2, p3 : pixel_type
  ) return pixel_type;

  function find_med3(
    p1, p2, p3 : pixel_type
  ) return pixel_type;

end filter_pkg;

package body filter_pkg is
  ------------------------------------------------------------------------------
  -- triple_sort 
  -- Purpose: Sorts three pixel values in descending order
  -- Returns: Concatenated result of sorted values (highest to lowest)
  ------------------------------------------------------------------------------
  function triple_sort(
    p1, p2, p3 : pixel_type
  ) return triple_sort_result is
    variable a, b, c : pixel_type;
    variable temp    : pixel_type;
    variable result  : triple_sort_result;
  begin
    -- Initialize variables
    a := p1;
    b := p2;
    c := p3;

    -- First compare-swap: ensure a > b
    if a < b then
      temp := a;
      a    := b;
      b    := temp;
    end if;

    -- Second compare-swap: ensure b > c
    if b < c then
      temp := b;
      b    := c;
      c    := temp;

      -- Re-compare first pair since b changed
      if a < b then
        temp := a;
        a    := b;
        b    := temp;
      end if;
    end if;

    -- Result will now be in descending order (largest to smallest)
    result := a & b & c;
    return result;
  end function;

  ------------------------------------------------------------------------------
  -- find_min3
  -- Finds the minimum value among three pixel values
  ------------------------------------------------------------------------------
  function find_min3(
    p1, p2, p3 : pixel_type
  ) return pixel_type is
  begin
    if p1 <= p2 then
      if p1 <= p3 then
        return p1;
      else
        return p3;
      end if;
    else
      if p2 <= p3 then
        return p2;
      else
        return p3;
      end if;
    end if;
  end function;

  ------------------------------------------------------------------------------
  -- find_max3
  -- Finds the maximum value among three pixel values
  ------------------------------------------------------------------------------
  function find_max3(
    p1, p2, p3 : pixel_type
  ) return pixel_type is
  begin
    if p1 >= p2 then
      if p1 >= p3 then
        return p1;
      else
        return p3;
      end if;
    else
      if p2 >= p3 then
        return p2;
      else
        return p3;
      end if;
    end if;
  end function;

  ------------------------------------------------------------------------------
  -- find_med3
  -- Finds the median value among three pixel values
  ------------------------------------------------------------------------------
  function find_med3(
    p1, p2, p3 : pixel_type
  ) return pixel_type is
  begin
    if (p1 <= p2) then
      if (p2 <= p3) then
        return p2;
      elsif (p1 <= p3) then
        return p3;
      else
        return p1;
      end if;
    else
      if (p1 <= p3) then
        return p1;
      elsif (p2 <= p3) then
        return p3;
      else
        return p2;
      end if;
    end if;
  end function;

end filter_pkg;