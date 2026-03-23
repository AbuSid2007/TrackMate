import httpx
from typing import Optional


class FoodService:
    BASE_URL = "https://world.openfoodfacts.org"

    async def search(self, query: str, page: int = 1) -> list[dict]:
        """Search Open Food Facts by name."""
        url = f"{self.BASE_URL}/cgi/search.pl"
        params = {
            "search_terms": query,
            "search_simple": 1,
            "action": "process",
            "json": 1,
            "page_size": 20,
            "page": page,
            "fields": "code,product_name,nutriments,serving_size,brands",
            "countries_tags": "india",  # bias toward Indian products
        }

        async with httpx.AsyncClient(timeout=10) as client:
            response = await client.get(url, params=params)
            response.raise_for_status()
            data = response.json()

        products = data.get("products", [])
        results = []

        for p in products:
            name = p.get("product_name", "").strip()
            if not name:
                continue

            nutriments = p.get("nutriments", {})
            results.append({
                "id": p.get("code", ""),
                "name": name,
                "brand": p.get("brands", ""),
                "calories_per_100g": self._safe_float(nutriments.get("energy-kcal_100g") or nutriments.get("energy_100g")),
                "protein_per_100g": self._safe_float(nutriments.get("proteins_100g")),
                "carbs_per_100g": self._safe_float(nutriments.get("carbohydrates_100g")),
                "fat_per_100g": self._safe_float(nutriments.get("fat_100g")),
                "serving_size_g": self._parse_serving(p.get("serving_size", "100g")),
                "serving_label": p.get("serving_size", "100g") or "100g",
            })

        return results

    async def get_by_barcode(self, barcode: str) -> Optional[dict]:
        """Fetch a specific product by barcode."""
        url = f"{self.BASE_URL}/api/v0/product/{barcode}.json"
        async with httpx.AsyncClient(timeout=10) as client:
            response = await client.get(url)
            if response.status_code != 200:
                return None
            data = response.json()

        if data.get("status") != 1:
            return None

        p = data.get("product", {})
        nutriments = p.get("nutriments", {})
        name = p.get("product_name", "").strip()
        if not name:
            return None

        return {
            "id": barcode,
            "name": name,
            "brand": p.get("brands", ""),
            "calories_per_100g": self._safe_float(nutriments.get("energy-kcal_100g")),
            "protein_per_100g": self._safe_float(nutriments.get("proteins_100g")),
            "carbs_per_100g": self._safe_float(nutriments.get("carbohydrates_100g")),
            "fat_per_100g": self._safe_float(nutriments.get("fat_100g")),
            "serving_size_g": self._parse_serving(p.get("serving_size", "100g")),
            "serving_label": p.get("serving_size", "100g") or "100g",
        }

    def _safe_float(self, value) -> float:
        try:
            return round(float(value), 2) if value is not None else 0.0
        except (TypeError, ValueError):
            return 0.0

    def _parse_serving(self, serving_str: str) -> float:
        """Extract grams from serving string like '30g' or '1 cup (240ml)'."""
        if not serving_str:
            return 100.0
        import re
        match = re.search(r"(\d+\.?\d*)\s*g", serving_str, re.IGNORECASE)
        if match:
            return float(match.group(1))
        match = re.search(r"(\d+\.?\d*)\s*ml", serving_str, re.IGNORECASE)
        if match:
            return float(match.group(1))
        return 100.0


food_service = FoodService()