import '../models/product.dart';

class MockData {
  MockData._();

  static const List<ProductCategory> categories = [
    ProductCategory(
      id: 'dry-food',
      name: 'Dry Food',
      petType: PetType.dog,
      subtitle: 'Crispy kibble for daily nutrition',
    ),
    ProductCategory(
      id: 'wet-food',
      name: 'Wet Food',
      petType: PetType.cat,
      subtitle: 'Moist meals cats crave',
    ),
    ProductCategory(
      id: 'treats',
      name: 'Treats',
      petType: PetType.dog,
      subtitle: 'Rewards for good boys',
    ),
    ProductCategory(
      id: 'cat-litter',
      name: 'Cat Litter',
      petType: PetType.cat,
      subtitle: 'Odor control & clumping',
    ),
    ProductCategory(
      id: 'bird-seed',
      name: 'Bird Seed',
      petType: PetType.bird,
      subtitle: 'Premium mixes for parrots',
    ),
    ProductCategory(
      id: 'fish-food',
      name: 'Fish Food',
      petType: PetType.fish,
      subtitle: 'Flakes & pellets',
    ),
    ProductCategory(
      id: 'toys',
      name: 'Toys',
      petType: PetType.dog,
      subtitle: 'Chew, fetch & play',
    ),
    ProductCategory(
      id: 'accessories',
      name: 'Accessories',
      petType: PetType.cat,
      subtitle: 'Bowls, beds & more',
    ),
  ];

  static final List<Product> products = [
    Product(
      id: 'p1',
      name: 'Salmon & Rice Formula',
      subtitle: 'Adult Dog Dry Food',
      categoryId: 'dry-food',
      petType: PetType.dog,
      price: 28.99,
      originalPrice: 34.99,
      imageUrl: 'https://images.unsplash.com/photo-1589941013453-ec89f33b5e95?w=600',
      images: [
        'https://images.unsplash.com/photo-1589941013453-ec89f33b5e95?w=800',
        'https://images.unsplash.com/photo-1568640347023-a616a30bc3bd?w=800',
        'https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=800',
      ],
      rating: 4.8,
      reviewCount: 1284,
      brand: 'PetPro',
      weightGrams: 5000,
      stock: 47,
      badges: ['Just In', 'Bestseller'],
      colorways: ['Salmon', 'Chicken', 'Beef'],
      description:
          'Premium dry food crafted with real salmon as the first ingredient. '
          'Supports healthy skin, a shiny coat, and lean muscle. No artificial '
          'colors, flavors, or preservatives.',
      ingredients:
          'Salmon, rice, chicken meal, barley, oat groats, fish meal, beet pulp, '
          'flaxseed, natural flavor, vitamins (A, D3, E, B-complex), minerals '
          '(zinc, selenium), taurine.',
      nutrition: {
        'Protein': '26%',
        'Fat': '16%',
        'Fiber': '4%',
        'Moisture': '10%',
      },
    ),
    Product(
      id: 'p2',
      name: 'Chicken & Veggie Stew',
      subtitle: 'Wet Cat Food — 24 Pack',
      categoryId: 'wet-food',
      petType: PetType.cat,
      price: 32.50,
      imageUrl: 'https://images.unsplash.com/photo-1574144611937-0df059b5ef3e?w=600',
      images: [
        'https://images.unsplash.com/photo-1574144611937-0df059b5ef3e?w=800',
        'https://images.unsplash.com/photo-1592194996308-7b43878e84a6?w=800',
      ],
      rating: 4.7,
      reviewCount: 932,
      brand: 'FelineFirst',
      weightGrams: 2400,
      stock: 22,
      badges: ['Member Exclusive'],
      colorways: ['Chicken', 'Tuna'],
      description:
          'Tender chicken pieces with garden vegetables in a savory gravy. '
          'Crafted with real meat and zero by-product meals.',
      ingredients: 'Chicken, vegetable broth, carrots, peas, potato starch, '
          'sunflower oil, taurine, vitamins.',
      nutrition: {
        'Protein': '10%',
        'Fat': '5%',
        'Fiber': '1%',
        'Moisture': '82%',
      },
    ),
    Product(
      id: 'p3',
      name: 'Peanut Butter Bones',
      subtitle: 'Natural Dog Treats',
      categoryId: 'treats',
      petType: PetType.dog,
      price: 12.99,
      originalPrice: 15.99,
      imageUrl: 'https://images.unsplash.com/photo-1623387641168-d9803ddd06f2?w=600',
      images: [
        'https://images.unsplash.com/photo-1623387641168-d9803ddd06f2?w=800',
      ],
      rating: 4.9,
      reviewCount: 2104,
      brand: 'BarkBox',
      weightGrams: 400,
      stock: 89,
      badges: ['Just In'],
      colorways: ['Peanut', 'Bacon'],
      description:
          'Long-lasting chew bones made with real peanut butter. Helps clean '
          'teeth and freshen breath while your pup enjoys hours of fun.',
      ingredients: 'Wheat flour, peanut butter, honey, vegetable oil, baking '
          'soda, vanilla extract.',
      nutrition: {
        'Protein': '12%',
        'Fat': '8%',
        'Fiber': '2%',
      },
    ),
    Product(
      id: 'p4',
      name: 'Clump & Seal Litter',
      subtitle: 'Odor Control — 18 kg',
      categoryId: 'cat-litter',
      petType: PetType.cat,
      price: 24.00,
      imageUrl: 'https://images.unsplash.com/photo-1592194996308-7b43878e84a6?w=600',
      images: [
        'https://images.unsplash.com/photo-1592194996308-7b43878e84a6?w=800',
      ],
      rating: 4.6,
      reviewCount: 567,
      brand: 'PurePaw',
      weightGrams: 18000,
      stock: 14,
      badges: ['Bestseller'],
      colorways: ['Original', 'Lavender'],
      description:
          'Clumping clay litter with activated charcoal for 7-day odor control. '
          'Low-dust formula keeps your home fresh and clean.',
      ingredients: 'Bentonite clay, activated charcoal, mineral fragrance.',
      nutrition: {
        'Dust': 'Low',
        'Clumping': 'Strong',
      },
    ),
    Product(
      id: 'p5',
      name: 'Tropical Parrot Mix',
      subtitle: 'Premium Bird Seed Blend',
      categoryId: 'bird-seed',
      petType: PetType.bird,
      price: 18.75,
      imageUrl: 'https://images.unsplash.com/photo-1522858547137-f1dcec554f55?w=600',
      images: [
        'https://images.unsplash.com/photo-1522858547137-f1dcec554f55?w=800',
      ],
      rating: 4.5,
      reviewCount: 198,
      brand: 'SkyFeather',
      weightGrams: 1500,
      stock: 31,
      badges: ['Recycled Materials'],
      colorways: ['Tropical', 'Mediterranean'],
      description:
          'A colorful blend of seeds, dried fruits, and nuts formulated for '
          'medium to large parrots. Encourages natural foraging behavior.',
      ingredients: 'Sunflower seeds, safflower, dried papaya, banana chips, '
          'almonds, pumpkin seeds.',
      nutrition: {
        'Protein': '14%',
        'Fat': '20%',
        'Fiber': '12%',
      },
    ),
    Product(
      id: 'p6',
      name: 'Tropical Flake Medley',
      subtitle: 'Tropical Fish Food',
      categoryId: 'fish-food',
      petType: PetType.fish,
      price: 8.50,
      originalPrice: 10.99,
      imageUrl: 'https://images.unsplash.com/photo-1522069169874-c58ec4b76be5?w=600',
      images: [
        'https://images.unsplash.com/photo-1522069169874-c58ec4b76be5?w=800',
      ],
      rating: 4.4,
      reviewCount: 423,
      brand: 'AquaLife',
      weightGrams: 200,
      stock: 120,
      badges: ['Just In'],
      colorways: ['Tropical', 'Goldfish'],
      description:
          'A balanced daily diet for tropical aquarium fish. Enhances natural '
          'color with spirulina and astaxanthin.',
      ingredients: 'Fish meal, wheat flour, spirulina, shrimp meal, vitamins.',
      nutrition: {
        'Protein': '42%',
        'Fat': '8%',
        'Fiber': '3%',
      },
    ),
    Product(
      id: 'p7',
      name: 'Rope Tug Toy',
      subtitle: 'Interactive Dog Toy',
      categoryId: 'toys',
      petType: PetType.dog,
      price: 14.99,
      imageUrl: 'https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=600',
      images: [
        'https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=800',
      ],
      rating: 4.7,
      reviewCount: 812,
      brand: 'PlayPup',
      weightGrams: 250,
      stock: 67,
      badges: ['Coming Soon'],
      colorways: ['Multi', 'Red', 'Blue'],
      description:
          'Heavy-duty cotton rope toy for tug-of-war and fetch. Cleans teeth '
          'as your dog chews.',
      ingredients: '100% natural cotton rope.',
      nutrition: {},
    ),
    Product(
      id: 'p8',
      name: 'Ceramic Slow Feeder',
      subtitle: 'Anti-Choke Cat Bowl',
      categoryId: 'accessories',
      petType: PetType.cat,
      price: 19.99,
      imageUrl: 'https://images.unsplash.com/photo-1583511655826-05700d52f4d9?w=600',
      images: [
        'https://images.unsplash.com/photo-1583511655826-05700d52f4d9?w=800',
      ],
      rating: 4.6,
      reviewCount: 354,
      brand: 'PurePaw',
      weightGrams: 600,
      stock: 28,
      badges: [],
      colorways: ['White', 'Gray', 'Pink'],
      description:
          'Whisker-friendly ceramic bowl with raised ridges to slow down fast '
          'eaters and reduce bloating.',
      ingredients: 'Ceramic, food-safe glaze.',
      nutrition: {},
    ),
    Product(
      id: 'p9',
      name: 'Beef & Brown Rice',
      subtitle: 'Adult Dog Dry Food',
      categoryId: 'dry-food',
      petType: PetType.dog,
      price: 31.99,
      imageUrl: 'https://images.unsplash.com/photo-1568640347023-a616a30bc3bd?w=600',
      images: [
        'https://images.unsplash.com/photo-1568640347023-a616a30bc3bd?w=800',
      ],
      rating: 4.7,
      reviewCount: 643,
      brand: 'PetPro',
      weightGrams: 6000,
      stock: 41,
      badges: [],
      colorways: ['Beef', 'Chicken'],
      description:
          'Hearty beef flavor combined with wholesome brown rice. Supports '
          'joint health with added glucosamine and chondroitin.',
      ingredients: 'Beef, brown rice, chicken meal, barley, beet pulp, fish oil.',
      nutrition: {
        'Protein': '25%',
        'Fat': '15%',
        'Fiber': '4%',
      },
    ),
    Product(
      id: 'p10',
      name: 'Tuna Mousse',
      subtitle: 'Wet Cat Food — 12 Pack',
      categoryId: 'wet-food',
      petType: PetType.cat,
      price: 18.50,
      originalPrice: 22.00,
      imageUrl: 'https://images.unsplash.com/photo-1573865526739-10659fec78a5?w=600',
      images: [
        'https://images.unsplash.com/photo-1573865526739-10659fec78a5?w=800',
      ],
      rating: 4.8,
      reviewCount: 1102,
      brand: 'FelineFirst',
      weightGrams: 1200,
      stock: 35,
      badges: ['Bestseller'],
      colorways: ['Tuna', 'Salmon'],
      description:
          'Velvety tuna mousse that cats adore. Made with real ocean tuna and '
          'no artificial additives.',
      ingredients: 'Tuna, fish broth, sunflower oil, taurine, vitamins.',
      nutrition: {
        'Protein': '11%',
        'Fat': '4%',
        'Moisture': '83%',
      },
    ),
    Product(
      id: 'p11',
      name: 'Dental Chew Sticks',
      subtitle: 'Daily Dental Care',
      categoryId: 'treats',
      petType: PetType.dog,
      price: 9.99,
      imageUrl: 'https://images.unsplash.com/photo-1583512603805-3cc6b41f3edb?w=600',
      images: [
        'https://images.unsplash.com/photo-1583512603805-3cc6b41f3edb?w=800',
      ],
      rating: 4.5,
      reviewCount: 528,
      brand: 'BarkBox',
      weightGrams: 300,
      stock: 75,
      badges: [],
      colorways: ['Mint', 'Chicken'],
      description:
          'Crispy chew sticks that scrub away plaque and tartar while your dog '
          'enjoys a satisfying crunch.',
      ingredients: 'Rice flour, chicken, parsley, mint.',
      nutrition: {
        'Protein': '10%',
        'Fat': '2%',
      },
    ),
    Product(
      id: 'p12',
      name: 'Canary Song Seed',
      subtitle: 'Premium Canary Mix',
      categoryId: 'bird-seed',
      petType: PetType.bird,
      price: 11.25,
      imageUrl: 'https://images.unsplash.com/photo-1444464666168-49d633b86797?w=600',
      images: [
        'https://images.unsplash.com/photo-1444464666168-49d633b86797?w=800',
      ],
      rating: 4.3,
      reviewCount: 142,
      brand: 'SkyFeather',
      weightGrams: 800,
      stock: 53,
      badges: [],
      colorways: ['Original'],
      description:
          'Carefully selected canary grass seeds and rape seed for vibrant '
          'feathers and song.',
      ingredients: 'Canary grass seed, rape seed, linseed, hemp seed.',
      nutrition: {
        'Protein': '16%',
        'Fat': '12%',
      },
    ),
  ];

  static List<Product> byCategory(String categoryId) =>
      products.where((p) => p.categoryId == categoryId).toList();

  static List<Product> byPetType(PetType type) =>
      products.where((p) => p.petType == type).toList();

  static List<Product> trending() {
    final list = List<Product>.from(products);
    list.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
    return list.take(6).toList();
  }

  static List<Product> onSale() => products.where((p) => p.onSale).toList();
}
