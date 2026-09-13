import Image from "next/image";
import { garmentSrc, type Garment } from "@/lib/wardrobe";

type Props = {
  garment: Garment;
  className?: string;
  sizes?: string;
  priority?: boolean;
};

export function GarmentPhoto({ garment, className, sizes, priority }: Props) {
  return (
    <Image
      src={garmentSrc(garment.key)}
      alt={garment.name}
      width={900}
      height={1100}
      sizes={sizes ?? "(max-width: 540px) 70vw, 360px"}
      className={className ?? "h-full w-full object-contain"}
      priority={priority}
    />
  );
}
